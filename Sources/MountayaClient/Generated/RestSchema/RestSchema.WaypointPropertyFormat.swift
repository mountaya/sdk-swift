// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// How a custom waypoint property's `value` should be rendered. The value is
  /// always carried as a string on the wire; this tells a renderer how to interpret
  /// and format it, so it never has to guess from the content. Null is equivalent
  /// to `text`.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct WaypointPropertyFormat: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// Plain text, rendered verbatim.
    public static let text: Self = "text"
    /// A number, rendered with the reader's locale grouping and decimal separator.
    public static let number: Self = "number"
    /// A duration in seconds, zero or more, rendered as hours and minutes.
    public static let duration: Self = "duration"
    /// A distance in meters, zero or more, rendered in the reader's length unit.
    public static let distance: Self = "distance"
    /// An absolute URL, rendered as a link.
    public static let url: Self = "url"
    /// An RFC 3339 date-time, or a bare YYYY-MM-DD date, rendered in the reader's locale.
    public static let date: Self = "date"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
