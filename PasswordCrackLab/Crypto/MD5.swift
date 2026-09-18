import Foundation

/// Minimal, self-contained MD5 implementation (RFC 1321 pseudocode form).
/// CryptoKit deliberately has no MD5, so this bridges that gap without
/// pulling in CommonCrypto or a bridging header.
enum MD5 {
    private static let shiftAmounts: [UInt32] = [
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    ]

    private static let sineTable: [UInt32] = (0..<64).map { i in
        UInt32(truncatingIfNeeded: Int64(floor(abs(sin(Double(i + 1))) * 4294967296)))
    }

    static func hash(_ string: String) -> String {
        digestBytes(for: Array(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func digestBytes(for input: [UInt8]) -> [UInt8] {
        var message = input
        let originalLengthBits = UInt64(message.count) * 8

        message.append(0x80)
        while message.count % 64 != 56 {
            message.append(0)
        }
        for i in 0..<8 {
            message.append(UInt8((originalLengthBits >> (8 * UInt64(i))) & 0xff))
        }

        var a0: UInt32 = 0x6745_2301
        var b0: UInt32 = 0xefcd_ab89
        var c0: UInt32 = 0x98ba_dcfe
        var d0: UInt32 = 0x1032_5476

        let chunkCount = message.count / 64
        for chunkIndex in 0..<chunkCount {
            let chunkStart = chunkIndex * 64
            var m = [UInt32](repeating: 0, count: 16)
            for j in 0..<16 {
                let base = chunkStart + j * 4
                m[j] = UInt32(message[base])
                    | (UInt32(message[base + 1]) << 8)
                    | (UInt32(message[base + 2]) << 16)
                    | (UInt32(message[base + 3]) << 24)
            }

            var a = a0, b = b0, c = c0, d = d0

            for i in 0..<64 {
                var f: UInt32
                var g: Int
                switch i {
                case 0..<16:
                    f = (b & c) | (~b & d)
                    g = i
                case 16..<32:
                    f = (d & b) | (~d & c)
                    g = (5 * i + 1) % 16
                case 32..<48:
                    f = b ^ c ^ d
                    g = (3 * i + 5) % 16
                default:
                    f = c ^ (b | ~d)
                    g = (7 * i) % 16
                }

                f = f &+ a &+ sineTable[i] &+ m[g]
                a = d
                d = c
                c = b
                b = b &+ rotateLeft(f, by: shiftAmounts[i])
            }

            a0 = a0 &+ a
            b0 = b0 &+ b
            c0 = c0 &+ c
            d0 = d0 &+ d
        }

        var result = [UInt8]()
        for value in [a0, b0, c0, d0] {
            result.append(UInt8(value & 0xff))
            result.append(UInt8((value >> 8) & 0xff))
            result.append(UInt8((value >> 16) & 0xff))
            result.append(UInt8((value >> 24) & 0xff))
        }
        return result
    }

    private static func rotateLeft(_ value: UInt32, by amount: UInt32) -> UInt32 {
        (value << amount) | (value >> (32 - amount))
    }
}
