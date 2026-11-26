// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Classification of the kind of way a stretch of route follows: the character of
  /// the path itself, rather than what it is paved with.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct WayType: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Unknown or unclassified way type.
    public static let unknown: Self = "unknown"
    /// State road or highway.
    public static let stateRoad: Self = "state-road"
    /// Standard road.
    public static let road: Self = "road"
    /// Urban street.
    public static let street: Self = "street"
    /// Walking or hiking path.
    public static let path: Self = "path"
    /// Unpaved track.
    public static let track: Self = "track"
    /// Designated cycleway.
    public static let cycleway: Self = "cycleway"
    /// Pedestrian footway.
    public static let footway: Self = "footway"
    /// Stairs or steps.
    public static let steps: Self = "steps"
    /// Ferry crossing.
    public static let ferry: Self = "ferry"
    /// Road under construction.
    public static let construction: Self = "construction"

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
