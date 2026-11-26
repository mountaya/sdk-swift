import Foundation

/// CodedTimestamp is how a property the contract declares a timestamp is read and written:
/// through the anchored rule, whatever the decoder's own date strategy.
///
/// A generated type decodes its timestamps itself, so it reads the wire the same way under any
/// `JSONDecoder` a consumer configures, and a value that fails the anchor fails the decode
/// instead of becoming whatever a formatter makes of it.
package struct CodedTimestamp: Sendable, Hashable, Codable {
  let date: Date

  init(_ date: Date) {
    self.date = date
  }

  package init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let text = try container.decode(String.self)
    guard let date = Timestamp.date(from: text) else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "not a full timestamp with a zone, as the contract writes one"
      )
    }
    self.date = date
  }

  package func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(Timestamp.string(from: date))
  }
}
