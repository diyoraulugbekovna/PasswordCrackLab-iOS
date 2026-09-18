import CryptoKit
import Foundation
import Security

/// Everything the app knows about turning a password into a "stored"
/// representation. Nothing in this file touches the network — it's pure,
/// local, on-device computation via CryptoKit / the bundled MD5 & PBKDF2.
enum HashingService {
    static let pbkdf2Iterations = 120_000

    static func computeHash(mode: HashMode, password: String, saltHex: String) -> String {
        switch mode {
        case .md5:
            return MD5.hash(saltHex + password)
        case .sha1:
            let digest = Insecure.SHA1.hash(data: Data((saltHex + password).utf8))
            return digest.map { String(format: "%02x", $0) }.joined()
        case .sha256:
            let digest = SHA256.hash(data: Data((saltHex + password).utf8))
            return digest.map { String(format: "%02x", $0) }.joined()
        case .pbkdf2:
            let saltData = Data(hexString: saltHex) ?? Data()
            let derived = PBKDF2.deriveKey(
                password: Data(password.utf8),
                salt: saltData,
                iterations: pbkdf2Iterations
            )
            return derived.map { String(format: "%02x", $0) }.joined()
        }
    }

    static func randomSaltHex(byteCount: Int = 16) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    init?(hexString: String) {
        guard hexString.count % 2 == 0 else { return nil }
        var data = Data(capacity: hexString.count / 2)
        var idx = hexString.startIndex
        while idx < hexString.endIndex {
            let nextIdx = hexString.index(idx, offsetBy: 2)
            guard let byte = UInt8(hexString[idx..<nextIdx], radix: 16) else { return nil }
            data.append(byte)
            idx = nextIdx
        }
        self = data
    }
}
