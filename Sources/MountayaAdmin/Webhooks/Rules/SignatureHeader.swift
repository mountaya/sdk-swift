/// SignatureHeader is what a `Mountaya-Signature` header states: when the delivery was signed, and
/// each signature, `t=<unix seconds>,v1=<signature>` with one `v1` for each secret in force.
struct SignatureHeader: Sendable, Hashable {
  /// stated is the header's `t` as written, which is what a `v1` signs.
  let stated: String
  /// timestamp is the header's `t`: the Unix time, in seconds, the delivery was signed at.
  let timestamp: Int64
  /// signatures is every `v1` of the header, in the order written.
  let signatures: [String]

  /// largestSeconds is the largest `t` read, the largest whole number a double holds exactly and
  /// so the largest every SDK reads alike: one past it is no timestamp any SDK reads.
  static let largestSeconds: Int64 = 9_007_199_254_740_991

  /// isMissing is true for a header the request does not carry, or one that holds nothing but
  /// white space, which states no signature.
  static func isMissing(_ header: String?) -> Bool {
    guard let header else { return true }
    return header.unicodeScalars.allSatisfy(isWhiteSpace)
  }

  /// parse reads a header, or returns nil where it is not one: an element that is no `key=value`
  /// pair, no `t` or more than one, a `t` that is not whole seconds in digits alone, or no `v1`.
  ///
  /// The elements are what lies between the commas, each key and value with the white space around
  /// it trimmed. A key other than `t` and `v1` names a signature scheme this release does not
  /// compute and is passed over, so a header that adds one beside `v1` still verifies.
  static func parse(_ header: String) -> SignatureHeader? {
    var timestamps: [String] = []
    var signatures: [String] = []
    for element in header.unicodeScalars.split(separator: ",", omittingEmptySubsequences: false) {
      guard let separator = element.firstIndex(of: "=") else { return nil }
      let key = trimmed(element[..<separator])
      let value = trimmed(element[element.index(after: separator)...])
      if key.unicodeScalars.elementsEqual("t".unicodeScalars) {
        timestamps.append(value)
      } else if key.unicodeScalars.elementsEqual("v1".unicodeScalars) {
        signatures.append(value)
      }
    }
    guard timestamps.count == 1, let stated = timestamps.first,
      let timestamp = wholeSeconds(stated), !signatures.isEmpty
    else {
      return nil
    }
    return SignatureHeader(stated: stated, timestamp: timestamp, signatures: signatures)
  }

  /// wholeSeconds reads a `t` written in the digits `0` to `9` alone, leading zeros included, or
  /// returns nil where it is empty, holds any other character, or names more than
  /// `largestSeconds`.
  static func wholeSeconds(_ text: String) -> Int64? {
    guard !text.isEmpty else { return nil }
    var value: Int64 = 0
    for scalar in text.unicodeScalars {
      guard ("0"..."9").contains(scalar) else { return nil }
      value = value * 10 + Int64(scalar.value - 0x30)
      guard value <= largestSeconds else { return nil }
    }
    return value
  }

  /// trimmed is a run of scalars with the white space at either end removed.
  private static func trimmed(_ scalars: Substring.UnicodeScalarView) -> String {
    var view = scalars
    while let first = view.first, isWhiteSpace(first) {
      view.removeFirst()
    }
    while let last = view.last, isWhiteSpace(last) {
      view.removeLast()
    }
    return String(Substring(view))
  }

  /// isWhiteSpace is true for the white space trimmed from either end of a key and a value: HTTP's
  /// own, the space and the tab, and every other character ECMAScript's `trim` removes, the line
  /// feed, the vertical tab, the form feed, the carriage return, every space separator, the line
  /// and paragraph separators and the byte order mark, so a header reads here as `sdk-typescript`
  /// reads it, the set the contract names (`transport.webhooks.verify-signature`).
  private static func isWhiteSpace(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x09...0x0D, 0x20, 0xA0, 0x1680, 0x2000...0x200A, 0x2028, 0x2029, 0x202F, 0x205F,
      0x3000, 0xFEFF:
      true
    default:
      false
    }
  }
}
