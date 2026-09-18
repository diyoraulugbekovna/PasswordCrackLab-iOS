import Foundation

/// Holds state across LoginView -> AnalyzingView -> ResultsView.
/// Everything here lives only for the current session in memory; nothing
/// is written to disk and nothing is ever sent over the network.
@MainActor
final class CrackSessionViewModel: ObservableObject {
    enum Screen: Equatable {
        case login
        case analyzing
        case results
    }

    @Published var screen: Screen = .login

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var hashMode: HashMode = .sha256

    @Published private(set) var saltHex: String = ""
    @Published private(set) var storedHash: String = ""

    @Published private(set) var phase: CrackPhase = .idle
    @Published private(set) var attempts: Int = 0
    @Published private(set) var elapsed: TimeInterval = 0

    @Published private(set) var outcome: CrackOutcome?

    private var currentTask: Task<Void, Never>?

    func submit() {
        guard !password.isEmpty else { return }

        let mode = hashMode
        let pwd = password
        let userEmail = email
        let salt = HashingService.randomSaltHex()
        let hash = HashingService.computeHash(mode: mode, password: pwd, saltHex: salt)

        phase = .idle
        attempts = 0
        elapsed = 0
        outcome = nil
        saltHex = salt
        storedHash = hash
        screen = .analyzing

        currentTask?.cancel()
        currentTask = Task.detached(priority: .userInitiated) { [weak self] in
            let result = await CrackingEngine.run(password: pwd, email: userEmail, mode: mode, saltHex: salt) { phase, attempts, elapsed in
                await MainActor.run {
                    self?.phase = phase
                    self?.attempts = attempts
                    self?.elapsed = elapsed
                }
            }
            await MainActor.run {
                self?.applyOutcome(result, mode: mode)
            }
        }
    }

    func resetForNewAttempt() {
        currentTask?.cancel()
        currentTask = nil
        email = ""
        password = ""
        outcome = nil
        phase = .idle
        attempts = 0
        elapsed = 0
        saltHex = ""
        storedHash = ""
        screen = .login
    }

    private func applyOutcome(_ result: EngineOutcome, mode: HashMode) {
        switch result {
        case .found(let password, let method, let attempts, let elapsed):
            self.attempts = attempts
            self.elapsed = elapsed

            let reason: String
            if method.hasPrefix("Personal info") {
                reason = "This password was guessed directly from the email address you entered — " +
                    "reusing your email, username, or a piece of your name as your password makes it " +
                    "trivial for anyone who already knows (or can find) that email to guess."
            } else if method.hasPrefix("Dictionary") {
                reason = "This password (or a close variant of it) appears in common leaked-password " +
                    "lists, so it's one of the very first guesses an automated attacker would try."
            } else {
                reason = "This password is short and/or draws from a limited set of characters, so it " +
                    "fell within reach of a capped brute-force sweep almost immediately."
            }

            outcome = .exposed(
                ExposedResult(password: password, method: method, attempts: attempts, elapsed: elapsed, reason: reason)
            )

        case .notFound(let attempts, let elapsed, let length, let charsetSize, let keyspace, let estimate):
            self.attempts = attempts
            self.elapsed = elapsed

            var reason = "Its length (\(length) characters) and character variety " +
                "(\(charsetSize)-character set) push the keyspace up to roughly " +
                "\(String(format: "%.2e", keyspace)) possibilities — computationally expensive to " +
                "guess even before the hashing method is considered."
            if mode == .pbkdf2 {
                reason += " On top of that, this slow-hash mode multiplies the cost of every single " +
                    "guess, which is exactly what algorithms like bcrypt and argon2 are designed to do."
            } else {
                reason += " Note that a fast hash like this offers little extra protection on its own " +
                    "— a slow hash (see the last row above) would raise the cost far more."
            }

            outcome = .safe(
                SafeResult(
                    attempts: attempts,
                    elapsed: elapsed,
                    passwordLength: length,
                    charsetSize: charsetSize,
                    keyspace: keyspace,
                    estimate: estimate,
                    reason: reason
                )
            )
        }

        screen = .results
    }
}
