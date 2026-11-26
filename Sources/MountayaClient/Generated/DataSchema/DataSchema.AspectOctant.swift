// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Compass octant of a downhill aspect direction.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct AspectOctant: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// North-facing (337.5-22.5 degrees).
    public static let north: Self = "NORTH"
    /// Northeast-facing (22.5-67.5 degrees).
    public static let northEast: Self = "NORTH_EAST"
    /// East-facing (67.5-112.5 degrees).
    public static let east: Self = "EAST"
    /// Southeast-facing (112.5-157.5 degrees).
    public static let southEast: Self = "SOUTH_EAST"
    /// South-facing (157.5-202.5 degrees).
    public static let south: Self = "SOUTH"
    /// Southwest-facing (202.5-247.5 degrees).
    public static let southWest: Self = "SOUTH_WEST"
    /// West-facing (247.5-292.5 degrees).
    public static let west: Self = "WEST"
    /// Northwest-facing (292.5-337.5 degrees).
    public static let northWest: Self = "NORTH_WEST"

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
