import Foundation

/// Loads the bundled, trimmed rockyou-style word list. Bundled locally so
/// the dictionary attack never needs a network request.
enum WordlistLoader {
    static func load() -> [String] {
        guard
            let url = Bundle.main.url(forResource: "common_passwords", withExtension: "txt"),
            let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            return []
        }
        return contents
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
