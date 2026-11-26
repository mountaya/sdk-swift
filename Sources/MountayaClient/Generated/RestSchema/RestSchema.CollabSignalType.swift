// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Discriminator for the kind of collaboration signal a client sends into an
  /// itinerary's real-time session over POST /v1/itineraries/{itinerary_id}/collab.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct CollabSignalType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The caller's current selection (a segment or waypoint), or null to clear it.
    public static let selection: Self = "selection"
    /// The caller's cursor position on the map, or null to clear it.
    public static let cursor: Self = "cursor"
    /// A request to take the soft edit lock on an entity.
    public static let lockAcquire: Self = "lock.acquire"
    /// A release of the soft edit lock the caller holds on an entity.
    public static let lockRelease: Self = "lock.release"
    /// An uncommitted draft of an entity the caller is editing under its lock.
    public static let draftUpdate: Self = "draft.update"
    /// A clear of the caller's uncommitted draft for an entity.
    public static let draftClear: Self = "draft.clear"

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
