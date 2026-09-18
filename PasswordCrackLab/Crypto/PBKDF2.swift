import CryptoKit
import Foundation

/// PBKDF2-HMAC-SHA256 built on top of CryptoKit's HMAC, since CryptoKit
/// doesn't expose PBKDF2 directly. This stands in for a real slow hash like
/// bcrypt/argon2 for teaching purposes — the point is that every guess costs
/// `iterations` HMAC computations instead of one.
enum PBKDF2 {
    static func deriveKey(password: Data, salt: Data, iterations: Int, keyLength: Int = 32) -> Data {
        let hLen = 32 // SHA-256 output length in bytes
        let numBlocks = Int(ceil(Double(keyLength) / Double(hLen)))
        var derivedKey = Data()
        let key = SymmetricKey(data: password)

        for blockIndex in 1...numBlocks {
            var blockIndexBE = UInt32(blockIndex).bigEndian
            var salted = salt
            withUnsafeBytes(of: &blockIndexBE) { salted.append(contentsOf: $0) }

            var u = Data(HMAC<SHA256>.authenticationCode(for: salted, using: key))
            var result = u

            if iterations > 1 {
                for _ in 1..<iterations {
                    u = Data(HMAC<SHA256>.authenticationCode(for: u, using: key))
                    for i in 0..<result.count {
                        result[i] ^= u[i]
                    }
                }
            }
            derivedKey.append(result)
        }
        return derivedKey.prefix(keyLength)
    }
}
