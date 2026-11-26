import Foundation

/// ResolutionFile is what the gate reads of a `Package.resolved`: the `originHash` SwiftPM wrote
/// into it, and the one SwiftPM reads off the package's manifest now.
///
/// SwiftPM writes a resolution file's `originHash` as the SHA-256 of its root package's manifest,
/// byte for byte, so an edit of the manifest, a comment's included, leaves the file's hash stale.
/// A stale hash makes the next resolution start afresh, and SwiftPM 6.4 writes such a file
/// without the pins a trait gates (SPEC.md section 2), so the gate catches one before a build does,
/// and needs no network to: the hash is computed here, never asked of SwiftPM.
package enum ResolutionFile {
  /// recordedOriginHash is the `originHash` a resolution file holds, or nil where it holds none.
  package static func recordedOriginHash(in text: String) -> String? {
    (try? OrderedJSON.parse(text))?["originHash"]?.stringValue
  }

  /// originHash is the hash SwiftPM writes for a package whose manifest is `manifest`, in
  /// lowercase hexadecimal.
  package static func originHash(ofManifest manifest: Data) -> String {
    sha256([UInt8](manifest)).map { byte in
      let digits = String(byte, radix: 16)
      return byte < 16 ? "0" + digits : digits
    }.joined()
  }

  /// sha256 is the SHA-256 digest of a message, as FIPS 180-4 defines it.
  package static func sha256(_ message: [UInt8]) -> [UInt8] {
    var hash: [UInt32] = [
      0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a,
      0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19,
    ]
    var padded = message
    padded.append(0x80)
    while padded.count % 64 != 56 {
      padded.append(0)
    }
    let bits = UInt64(message.count) &* 8
    for shift in stride(from: 56, through: 0, by: -8) {
      padded.append(UInt8(truncatingIfNeeded: bits >> UInt64(shift)))
    }
    var words = [UInt32](repeating: 0, count: 64)
    for chunk in stride(from: 0, to: padded.count, by: 64) {
      for index in 0..<16 {
        let at = chunk + index * 4
        words[index] =
          UInt32(padded[at]) << 24 | UInt32(padded[at + 1]) << 16 | UInt32(padded[at + 2]) << 8
          | UInt32(padded[at + 3])
      }
      for index in 16..<64 {
        let early = words[index - 15]
        let late = words[index - 2]
        let sigma0 = rotated(early, by: 7) ^ rotated(early, by: 18) ^ (early >> 3)
        let sigma1 = rotated(late, by: 17) ^ rotated(late, by: 19) ^ (late >> 10)
        words[index] = words[index - 16] &+ sigma0 &+ words[index - 7] &+ sigma1
      }
      var (a, b, c, d) = (hash[0], hash[1], hash[2], hash[3])
      var (e, f, g, h) = (hash[4], hash[5], hash[6], hash[7])
      for index in 0..<64 {
        let sum1 = rotated(e, by: 6) ^ rotated(e, by: 11) ^ rotated(e, by: 25)
        let choice = (e & f) ^ (~e & g)
        let first = h &+ sum1 &+ choice &+ roundConstants[index] &+ words[index]
        let sum0 = rotated(a, by: 2) ^ rotated(a, by: 13) ^ rotated(a, by: 22)
        let majority = (a & b) ^ (a & c) ^ (b & c)
        let second = sum0 &+ majority
        (h, g, f, e) = (g, f, e, d &+ first)
        (d, c, b, a) = (c, b, a, first &+ second)
      }
      for (index, value) in [a, b, c, d, e, f, g, h].enumerated() {
        hash[index] = hash[index] &+ value
      }
    }
    return hash.flatMap { word in
      [
        UInt8(word >> 24), UInt8(truncatingIfNeeded: word >> 16),
        UInt8(truncatingIfNeeded: word >> 8),
        UInt8(truncatingIfNeeded: word),
      ]
    }
  }

  private static func rotated(_ word: UInt32, by count: UInt32) -> UInt32 {
    word >> count | word << (32 - count)
  }

  /// roundConstants is the first 32 bits of the fractional parts of the cube roots of the first
  /// 64 primes.
  private static let roundConstants: [UInt32] = [
    0x428a_2f98, 0x7137_4491, 0xb5c0_fbcf, 0xe9b5_dba5, 0x3956_c25b, 0x59f1_11f1, 0x923f_82a4,
    0xab1c_5ed5, 0xd807_aa98, 0x1283_5b01, 0x2431_85be, 0x550c_7dc3, 0x72be_5d74, 0x80de_b1fe,
    0x9bdc_06a7, 0xc19b_f174, 0xe49b_69c1, 0xefbe_4786, 0x0fc1_9dc6, 0x240c_a1cc, 0x2de9_2c6f,
    0x4a74_84aa, 0x5cb0_a9dc, 0x76f9_88da, 0x983e_5152, 0xa831_c66d, 0xb003_27c8, 0xbf59_7fc7,
    0xc6e0_0bf3, 0xd5a7_9147, 0x06ca_6351, 0x1429_2967, 0x27b7_0a85, 0x2e1b_2138, 0x4d2c_6dfc,
    0x5338_0d13, 0x650a_7354, 0x766a_0abb, 0x81c2_c92e, 0x9272_2c85, 0xa2bf_e8a1, 0xa81a_664b,
    0xc24b_8b70, 0xc76c_51a3, 0xd192_e819, 0xd699_0624, 0xf40e_3585, 0x106a_a070, 0x19a4_c116,
    0x1e37_6c08, 0x2748_774c, 0x34b0_bcb5, 0x391c_0cb3, 0x4ed8_aa4a, 0x5b9c_ca4f, 0x682e_6ff3,
    0x748f_82ee, 0x78a5_636f, 0x84c8_7814, 0x8cc7_0208, 0x90be_fffa, 0xa450_6ceb, 0xbef9_a3f7,
    0xc671_78f2,
  ]
}
