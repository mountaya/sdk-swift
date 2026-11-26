/// HeaderLookup reads a header out of a set of them, its name compared in any letter case, as
/// HTTP compares one.
///
/// Only `A` to `Z` fold: a header name is ASCII, and Unicode's case mapping, which lowers the
/// Kelvin sign to `k`, has no say in it.
enum HeaderLookup {
  /// value returns the value of the header named `name`, or nil where there is none. Where the
  /// set spells the name twice in two cases, their values are joined by a comma and a space, in
  /// the order of the names.
  static func value(of name: String, in headers: [String: String]) -> String? {
    let wanted = asciiLowercase(name)
    let values = headers.filter { asciiLowercase($0.key) == wanted }.sorted { $0.key < $1.key }
    guard !values.isEmpty else { return nil }
    return values.map(\.value).joined(separator: ", ")
  }

  /// folded returns `headers` as one map, each name in lowercase, `A` to `Z` folded alone, and the
  /// names a set spells twice in two cases holding their values joined by a comma and a space, in
  /// the order of the names: what `value(of:in:)` reads for each name, read once for all of them,
  /// so an answer's every header is then a lookup of its lowercase name. A set whose names hold no
  /// capital is folded already and comes back as it is.
  static func folded(_ headers: [String: String]) -> [String: String] {
    guard headers.keys.contains(where: { $0.utf8.contains(where: isCapital) }) else {
      return headers
    }
    var folded: [String: String] = [:]
    folded.reserveCapacity(headers.count)
    for (name, value) in headers.sorted(by: { $0.key < $1.key }) {
      let key = asciiLowercase(name)
      if let earlier = folded[key] {
        folded[key] = earlier + ", " + value
      } else {
        folded[key] = value
      }
    }
    return folded
  }

  /// value returns the value of the header named `name` in `folded`, a set `folded(_:)` folded,
  /// or nil where there is none: one lookup, whatever the set holds.
  static func value(of name: String, inFolded folded: [String: String]) -> String? {
    folded[asciiLowercase(name)]
  }

  /// contains returns whether the set holds a header named `name`, in any letter case.
  static func contains(_ name: String, in headers: [String: String]) -> Bool {
    let wanted = asciiLowercase(name)
    return headers.keys.contains { asciiLowercase($0) == wanted }
  }

  /// asciiLowercase returns `text` with each ASCII capital, `A` to `Z`, written as its small
  /// letter, and every other scalar as it is. Every word the client compares in any letter case,
  /// a header's name, a media type, a header's `true`, is folded by it.
  static func asciiLowercase(_ text: String) -> String {
    guard text.utf8.contains(where: isCapital) else { return text }
    return String(decoding: text.utf8.map { isCapital($0) ? $0 + 0x20 : $0 }, as: UTF8.self)
  }

  private static func isCapital(_ byte: UInt8) -> Bool {
    byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z")
  }
}
