// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// Which snapshot of a resource to read. `published` is the only accepted value:
  /// there is deliberately no `draft` spelling, because the parameter only ever
  /// narrows what the caller is served, and omitting it already means "whatever I
  /// am authorized to see". An unrecognized value is rejected with a validation
  /// error rather than silently ignored.
  ///
  /// Declared once and shared, because the same single-value vocabulary is accepted
  /// by the itinerary and zone reads on the Map Studio API and by the itinerary,
  /// zone and collection tiles and the collection's specification on the Tile
  /// API. A second value added here has to mean the same thing on both.
  ///
  /// It is one of two vocabularies spelled `surface` on this contract, and the one
  /// about CONTENT. `UsageTileSurface` names where a counted request came from,
  /// decided by the server after the fact. This one names which snapshot a single
  /// read returns, and is decided by the caller on every request.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ReadSurface: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Read the published snapshot, never the draft.
    public static let published: Self = "published"

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
