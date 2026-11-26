import Crypto
import Foundation

/// WebhookSignature is the signature a webhook delivery carries: the lowercase hexadecimal
/// HMAC-SHA256 of `<t>.<body>`, keyed by the endpoint's whole secret, `whsk_` included, where `<t>`
/// is the header's `t` as written and `<body>` the body's bytes exactly as they arrived.
enum WebhookSignature {
  private static let hexDigits = Array("0123456789abcdef".utf8)

  /// expected returns the signature of `body`, signed at the `t` written `stated`, under `secret`.
  static func expected(stated: String, body: Data, secret: String) -> String {
    hex(mac(key: Array(secret.utf8), message: Array("\(stated).".utf8) + Array(body)))
  }

  /// mac returns the HMAC-SHA256 of `message` under `key`, 32 bytes, an empty key read as the block
  /// of zeros RFC 2104 pads every key to, as every SDK reads it.
  static func mac(key: [UInt8], message: [UInt8]) -> [UInt8] {
    Array(HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key)))
  }

  /// hex spells bytes in lowercase hexadecimal, two characters a byte.
  static func hex(_ bytes: [UInt8]) -> String {
    var hex: [UInt8] = []
    hex.reserveCapacity(bytes.count * 2)
    for byte in bytes {
      hex.append(hexDigits[Int(byte >> 4)])
      hex.append(hexDigits[Int(byte & 0x0f)])
    }
    return String(decoding: hex, as: UTF8.self)
  }

  /// verifies returns whether any of `candidates` is `expected`.
  ///
  /// Every candidate is compared, a match found early included, so the time taken does not say
  /// which of the secrets in force signed the delivery.
  static func verifies(_ candidates: [String], expected: String) -> Bool {
    var verified = false
    for candidate in candidates {
      let matches = equalInConstantTime(candidate, expected)
      verified = matches || verified
    }
    return verified
  }

  /// equalInConstantTime returns whether two signatures are the same bytes, reading every byte of
  /// both whatever the first difference, so the time it takes says nothing about where they
  /// differ. A length is no secret: a candidate of another length is unequal at once.
  static func equalInConstantTime(_ candidate: String, _ expected: String) -> Bool {
    let candidate = Array(candidate.utf8)
    let expected = Array(expected.utf8)
    guard candidate.count == expected.count else { return false }
    var difference: UInt8 = 0
    for index in expected.indices {
      difference |= candidate[index] ^ expected[index]
    }
    return difference == 0
  }
}
