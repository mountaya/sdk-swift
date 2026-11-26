/// HeaderValue decides whether a string a request carries as a header can be one.
///
/// Every member of a credential, the client's language, an `Idempotency-Key`, an `If-Match`, a
/// cookie the client writes for a visitor, the id of a stream's last record it resumes from and the
/// value of a caller's own header ride a request as a header, so each is held to what a header
/// carries before any request leaves the process, and a caller's own header's name to what a field
/// name is.
enum HeaderValue {
  /// isBlank is true for a value that is empty or whitespace alone, which is a missing value
  /// rather than a malformed one.
  static func isBlank(_ value: String) -> Bool {
    value.allSatisfy(\.isWhitespace)
  }

  /// isCarried is true where every scalar of the value is printable ASCII, U+0020 to U+007E,
  /// which is what a header carries in every SDK (`sdk/SPEC.md` §1): a line break, a tab or
  /// another control character, a letter of Latin-1 such as `é` and any character past it are
  /// refused before any request. The loaders do not carry one alike: Apple's writes a Latin-1
  /// character as its one byte, and FoundationNetworking, over libcurl, as two UTF-8 bytes a
  /// server reads as two other characters, `é` as `Ã©`.
  static func isCarried(_ value: String) -> Bool {
    value.unicodeScalars.allSatisfy { (0x20...0x7E).contains($0.value) }
  }

  /// isToken is true where `name` is a field name as RFC 9110 writes one, a token: one or more
  /// letters, digits and `!#$%&'*+-.^_|~` or a backtick, as `sdk-dart` and `sdk-kotlin` hold a
  /// caller's header name to. A space, a colon, a quote, a bracket or a character past ASCII is no
  /// field name: a loader refuses it, or writes `X-Trace: a` as a header of its own.
  static func isToken(_ name: String) -> Bool {
    !name.isEmpty
      && name.unicodeScalars.allSatisfy { scalar in
        switch scalar.value {
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A: true
        default: tokenSymbols.unicodeScalars.contains(scalar)
        }
      }
  }

  /// tokenSymbols is every character a token holds beside the letters and digits of ASCII.
  private static let tokenSymbols = "!#$%&'*+-.^_`|~"

  /// uncarried names what a header refuses, for a refusal to say.
  static let uncarried =
    "a control character or a character outside printable ASCII, which no header carries"
}
