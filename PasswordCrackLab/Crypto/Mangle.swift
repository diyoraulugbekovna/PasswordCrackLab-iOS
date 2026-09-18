import Foundation

/// Mangling rules applied to dictionary words, mirroring what real cracking
/// rule sets (Hashcat/John the Ripper) do to expand a wordlist.
enum Mangle {
    private static let leetMap: [Character: Character] = [
        "a": "4", "e": "3", "i": "1", "o": "0", "s": "5",
    ]

    static func leetify(_ word: String) -> String {
        String(word.map { leetMap[Character($0.lowercased())] ?? $0 })
    }

    static func capitalize(_ word: String) -> String {
        guard let first = word.first else { return word }
        return first.uppercased() + word.dropFirst()
    }

    static func variants(for word: String, currentYear: Int) -> [String] {
        let cap = capitalize(word)
        let leet = leetify(word)
        let capLeet = leetify(cap)

        var set = Set<String>()
        set.insert(word)
        set.insert(cap)
        set.insert(word + "1")
        set.insert(word + "123")
        set.insert(word + String(currentYear))
        set.insert(word + String(currentYear - 1))
        set.insert(cap + "1")
        set.insert(cap + "123")
        set.insert(cap + String(currentYear))
        set.insert(leet)
        set.insert(capLeet)
        set.insert(leet + "123")

        return Array(set)
    }
}
