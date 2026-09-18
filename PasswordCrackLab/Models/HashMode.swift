import Foundation

enum HashMode: String, CaseIterable, Identifiable {
    case md5
    case sha1
    case sha256
    case pbkdf2

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .md5: return "MD5"
        case .sha1: return "SHA-1"
        case .sha256: return "SHA-256"
        case .pbkdf2: return "Slow hash — PBKDF2 (stand-in for bcrypt/argon2)"
        }
    }

    /// Fast, general-purpose hashes are the ones a GPU can brute force at billions/sec offline.
    var isFastHash: Bool {
        switch self {
        case .md5, .sha1, .sha256: return true
        case .pbkdf2: return false
        }
    }
}
