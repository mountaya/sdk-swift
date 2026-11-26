/// CodedURI is how a property the contract declares `format: uri` is read and written in a type a
/// request carries: read as the text the wire sent, as every address is, and written only where
/// it is the least RFC 3986 calls a URI, a scheme, a colon and at least one more character, none a
/// line break.
///
/// An address with no scheme, a path such as `/v1/x` or a host such as `www.example.com`, would be
/// sent nowhere a caller meant, so it fails the encode of the body it would leave in, which the
/// transport refuses as a `ConfigurationError` before any request. `sdk-kotlin`'s `Url` and
/// `sdk-dart`'s refuse the same strings. A type only an answer carries reads and writes its
/// addresses as `URI` does, whatever they hold.
package struct CodedURI: Sendable, Hashable, Codable {
  let address: URI

  init(_ address: URI) {
    self.address = address
  }

  package init(from decoder: any Decoder) throws {
    address = try URI(from: decoder)
  }

  package func encode(to encoder: any Encoder) throws {
    guard address.hasScheme else {
      throw EncodingError.invalidValue(
        address.text,
        EncodingError.Context(
          codingPath: encoder.codingPath,
          debugDescription:
            "`\(address.text)` is not a URL: a URL starts with a scheme, such as `https:`."
        ))
    }
    try address.encode(to: encoder)
  }
}
