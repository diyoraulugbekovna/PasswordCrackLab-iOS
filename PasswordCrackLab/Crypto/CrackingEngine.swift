import Foundation

/// Runs the cracking demo: email-derived guesses -> dictionary attack ->
/// bounded brute force -> mathematical estimate. Designed to run inside a
/// detached background Task so it never blocks the main actor / UI.
///
/// This only ever operates on the single password it's given in-memory for
/// this one call — nothing is persisted, and nothing leaves the device.
enum CrackingEngine {
    static let dictionaryTimeCap: TimeInterval = 3.0
    static let bruteForceTimeCap: TimeInterval = 3.0
    static let bruteForceAttemptsCap = 3_000_000
    static let bruteForceMaxLength = 6
    static let progressInterval: TimeInterval = 0.12

    private static let symbolSet = "!@#$%^&*()-_=+[]{};:,.<>?/"

    static func run(
        password: String,
        email: String,
        mode: HashMode,
        saltHex: String,
        onProgress: @escaping @Sendable (CrackPhase, Int, TimeInterval) async -> Void
    ) async -> EngineOutcome {
        let clock = ContinuousClock()
        let overallStart = clock.now

        let targetHash = HashingService.computeHash(mode: mode, password: password, saltHex: saltHex)

        var attempts = 0
        var lastProgress = clock.now
        let currentYear = Calendar.current.component(.year, from: Date())

        func elapsed(since start: ContinuousClock.Instant) -> TimeInterval {
            seconds(from: start.duration(to: clock.now))
        }

        // --- Phase 1: guesses derived from the email typed into this form ---
        await onProgress(.personalInfo, 0, 0)
        let emailCandidates = EmailCandidates.generate(fromEmail: email, currentYear: currentYear)
        for candidate in emailCandidates {
            attempts += 1
            let candidateHash = HashingService.computeHash(mode: mode, password: candidate, saltHex: saltHex)
            if candidateHash == targetHash {
                return .found(
                    password: candidate,
                    method: "Personal info attack (guessed from the email you entered)",
                    attempts: attempts,
                    elapsed: elapsed(since: overallStart)
                )
            }
            if elapsed(since: lastProgress) >= progressInterval {
                lastProgress = clock.now
                await onProgress(.personalInfo, attempts, elapsed(since: overallStart))
                await Task.yield()
            }
        }

        // --- Phase 2: dictionary attack ---
        await onProgress(.dictionary, attempts, elapsed(since: overallStart))
        let words = WordlistLoader.load()
        let dictStart = clock.now

        dictLoop: for word in words {
            for candidate in Mangle.variants(for: word, currentYear: currentYear) {
                attempts += 1
                let candidateHash = HashingService.computeHash(mode: mode, password: candidate, saltHex: saltHex)
                if candidateHash == targetHash {
                    return .found(
                        password: candidate,
                        method: "Dictionary attack (common password list + mangling rules)",
                        attempts: attempts,
                        elapsed: elapsed(since: overallStart)
                    )
                }
                if elapsed(since: lastProgress) >= progressInterval {
                    lastProgress = clock.now
                    await onProgress(.dictionary, attempts, elapsed(since: overallStart))
                    await Task.yield()
                }
                if elapsed(since: dictStart) > dictionaryTimeCap {
                    break dictLoop
                }
            }
        }

        // --- Phase 3: bounded brute force ---
        await onProgress(.bruteForce, attempts, elapsed(since: overallStart))
        let charset = buildCharset(password: password)
        let base = charset.count
        let bruteStart = clock.now

        bruteLoop: for length in 1...bruteForceMaxLength {
            var indices = [Int](repeating: 0, count: length)
            while true {
                attempts += 1
                let candidate = String(indices.map { charset[$0] })

                let candidateHash = HashingService.computeHash(mode: mode, password: candidate, saltHex: saltHex)
                if candidateHash == targetHash {
                    return .found(
                        password: candidate,
                        method: "Brute force (charset size \(base), length \(length))",
                        attempts: attempts,
                        elapsed: elapsed(since: overallStart)
                    )
                }

                if elapsed(since: lastProgress) >= progressInterval {
                    lastProgress = clock.now
                    await onProgress(.bruteForce, attempts, elapsed(since: overallStart))
                    await Task.yield()
                }

                if attempts >= bruteForceAttemptsCap || elapsed(since: bruteStart) > bruteForceTimeCap {
                    break bruteLoop
                }

                var pos = length - 1
                while pos >= 0 {
                    indices[pos] += 1
                    if indices[pos] < base { break }
                    indices[pos] = 0
                    pos -= 1
                }
                if pos < 0 { break } // exhausted every combination at this length
            }
        }

        // --- Phase 4: not cracked within caps -> mathematical estimate ---
        await onProgress(.estimating, attempts, elapsed(since: overallStart))
        let keyspace = pow(Double(base), Double(password.count))
        let avgAttempts = keyspace / 2

        var scenarios: [EstimateRow] = [
            EstimateRow(
                label: "Online, rate-limited login form",
                rateLabel: "~1–100 guesses/sec",
                seconds: avgAttempts / 10
            )
        ]
        if mode.isFastHash {
            scenarios.append(
                EstimateRow(
                    label: "Offline, fast unsalted-style hash + GPU cluster",
                    rateLabel: "~billions/sec",
                    seconds: avgAttempts / 20_000_000_000
                )
            )
        }
        scenarios.append(
            EstimateRow(
                label: "Offline, slow salted hash (bcrypt/argon2-style)",
                rateLabel: "~hundreds–thousands/sec",
                seconds: avgAttempts / 1000
            )
        )

        return .notFound(
            attempts: attempts,
            elapsed: elapsed(since: overallStart),
            passwordLength: password.count,
            charsetSize: base,
            keyspace: keyspace,
            estimate: scenarios
        )
    }

    private static func buildCharset(password: String) -> [Character] {
        let hasLower = password.contains { $0.isLowercase }
        let hasUpper = password.contains { $0.isUppercase }
        let hasDigit = password.contains { $0.isNumber }
        let hasSymbol = password.contains { !$0.isLetter && !$0.isNumber }

        var charset: [Character] = []
        if hasLower { charset += Array("abcdefghijklmnopqrstuvwxyz") }
        if hasUpper { charset += Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ") }
        if hasDigit { charset += Array("0123456789") }
        if hasSymbol { charset += Array(symbolSet) }
        if charset.isEmpty { charset = Array("abcdefghijklmnopqrstuvwxyz") }
        return charset
    }

    private static func seconds(from duration: Duration) -> TimeInterval {
        let components = duration.components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}
