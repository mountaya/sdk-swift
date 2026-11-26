import Crypto

/// PersistedQueryDigest is the digest an automatic persisted query sends in place of its
/// document.
///
/// The server recomputes it from the bytes it stores and compares strings, so a substitute is
/// not slower, it is wrong: it is SHA-256 over the document's exact UTF-8 bytes, whitespace
/// included, in lowercase hexadecimal.
enum PersistedQueryDigest {
  /// version is the persisted-query extension's version the digest is sent under.
  static let version = 1

  private static let hexDigits = Array("0123456789abcdef".utf8)

  /// digest returns the digest of a document.
  static func digest(of document: String) -> String {
    var hex: [UInt8] = []
    hex.reserveCapacity(64)
    for byte in SHA256.hash(data: Array(document.utf8)) {
      hex.append(hexDigits[Int(byte >> 4)])
      hex.append(hexDigits[Int(byte & 0x0f)])
    }
    return String(decoding: hex, as: UTF8.self)
  }
}
