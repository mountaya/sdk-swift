import Foundation

/// URI is a value the contract types `format: uri`, a web address, kept as the text it was
/// written in.
///
/// It is the one type of every such value, REST's `format: uri` and the Data API's `URL` scalar
/// alike, and it holds the text and parses nothing out of it: an answer is the API's account of
/// what it holds, and a client rewriting an address would hand its caller another one. So an
/// answer's address is read as the wire wrote it, whatever it holds, one with no scheme, one
/// holding a letter outside ASCII or a bare percent sign, and one Foundation's `URL` would rewrite,
/// its letter case, a default port or a dot segment, and none fails the answer it arrives in
/// (`sdk/SPEC.md` §4).
///
/// One a caller builds for a request is held to the least RFC 3986 calls a URI as it is written:
/// a scheme, a colon and at least one more character, none a line break. A body holding one with
/// no scheme, a path such as `/v1/x` or a host such as `www.example.com`, is refused with a
/// `ConfigurationError` before any request, rather than sent to be answered with a 400: a printed
/// type a request carries writes its addresses through that check, and one only an answer carries
/// writes each back as it was read, so an answer a caller keeps writes as it arrived.
///
/// `sdk-kotlin` and `sdk-dart` call the same type `Url`, a name Swift's Foundation holds.
///
/// Two values are equal where their texts hold the same scalars, so two spellings of one address
/// Unicode calls canonically equivalent are two addresses, as every rule that matches text reads
/// them (`sdk/SPEC.md` §7).
public struct URI: Sendable, Hashable, Codable, CustomStringConvertible {
  /// text is the address exactly as it was written.
  public let text: String

  /// Creates the address `text` writes, exactly as written.
  public init(_ text: String) {
    self.text = text
  }

  /// Creates the address Foundation's `url` writes, its absolute string.
  public init(_ url: URL) {
    self.text = url.absoluteString
  }

  /// url is Foundation's reading of the text, such as for a link a view opens, or nil where
  /// Foundation reads none. It may write the address otherwise than the text does.
  public var url: URL? {
    URL(string: text)
  }

  /// hasScheme is true where the text is the least RFC 3986 calls a URI: a scheme, an ASCII
  /// letter followed by letters, digits, `+`, `-` or `.`, then a colon, then at least one more
  /// character, none of them a line break. It is what a request holds an address it sends to.
  var hasScheme: Bool {
    let scalars = text.unicodeScalars
    guard let colon = scalars.firstIndex(of: ":"), let first = scalars.first,
      Self.isLetter(first), scalars[..<colon].allSatisfy(Self.isSchemeScalar)
    else {
      return false
    }
    let rest = scalars[scalars.index(after: colon)...]
    return !rest.isEmpty && !rest.contains(where: Self.lineBreaks.contains)
  }

  /// description is the text, exactly as written.
  public var description: String {
    text
  }

  /// Reads the address an answer carries as the JSON string it is, whatever it holds.
  public init(from decoder: any Decoder) throws {
    text = try decoder.singleValueContainer().decode(String.self)
  }

  /// encode writes the address as the JSON string it holds, exactly as written. A printed type a
  /// request carries writes it through `CodedURI` instead, which refuses one with no scheme.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(text)
  }

  /// Two addresses are equal where their texts hold the same scalars.
  public static func == (lhs: URI, rhs: URI) -> Bool {
    lhs.text.unicodeScalars.elementsEqual(rhs.text.unicodeScalars)
  }

  /// hash hashes the text's scalars, as `==` compares them.
  public func hash(into hasher: inout Hasher) {
    for scalar in text.unicodeScalars {
      hasher.combine(scalar.value)
    }
    hasher.combine(text.unicodeScalars.count)
  }

  /// lineBreaks is every scalar a regular expression's `.` does not match, so the rule refuses
  /// what `sdk-kotlin`'s pattern refuses.
  private static let lineBreaks: Set<Unicode.Scalar> = [
    "\n", "\r", "\u{85}", "\u{2028}", "\u{2029}",
  ]

  private static func isLetter(_ scalar: Unicode.Scalar) -> Bool {
    ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar)
  }

  private static func isSchemeScalar(_ scalar: Unicode.Scalar) -> Bool {
    isLetter(scalar) || ("0"..."9").contains(scalar) || scalar == "+" || scalar == "-"
      || scalar == "."
  }
}
