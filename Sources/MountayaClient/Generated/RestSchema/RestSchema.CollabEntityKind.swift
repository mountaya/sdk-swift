// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The family of a lockable collaboration entity. Each collaboration session
  /// guards the kinds its resource's writes check, and only those: an
  /// itinerary's session its segments, segment groups and waypoints, and a
  /// zone's session the zone itself. A lock or draft signal naming a kind its
  /// session does not guard is refused with `400` at `["entity", "kind"]` and
  /// takes no lock.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct CollabEntityKind: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// A segment of an itinerary, locked in that itinerary's session.
    public static let segment: Self = "segment"
    /// A group of consecutive segments of an itinerary, locked in that itinerary's session.
    public static let segmentGroup: Self = "segment-group"
    /// A waypoint of an itinerary, locked in that itinerary's session.
    public static let waypoint: Self = "waypoint"
    /// A zone, locked in that zone's own session.
    public static let zone: Self = "zone"

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
