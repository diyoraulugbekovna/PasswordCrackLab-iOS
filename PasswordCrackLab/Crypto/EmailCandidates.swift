import Foundation

/// Derives password guesses from the email address typed into this same
/// session's demo form — mirroring a real attacker technique: reusing a
/// known username/email (or the name buried inside it) as a password guess.
/// This only ever looks at the single email entered in this session; it
/// never touches real accounts, contacts, or breach data.
enum EmailCandidates {
    static func generate(fromEmail email: String, currentYear: Int) -> [String] {
        let localPart = String(email.split(separator: "@", maxSplits: 1).first ?? Substring(email))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard localPart.count >= 2 else { return [] }

        let separators = CharacterSet(charactersIn: "._-+0123456789")
        let tokens = localPart
            .components(separatedBy: separators)
            .filter { $0.count >= 2 }

        var candidates = Set<String>()
        candidates.insert(localPart)
        candidates.insert(localPart.lowercased())

        for token in tokens {
            for variant in Mangle.variants(for: token.lowercased(), currentYear: currentYear) {
                candidates.insert(variant)
            }
        }

        return Array(candidates)
    }
}
