// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Maneuver type for a turn-by-turn direction step, derived from the routing
  /// engine's instruction analysis. Clients template localized instruction text from
  /// this type plus the step's name.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ManeuverType: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Turn left.
    public static let turnLeft: Self = "TURN_LEFT"
    /// Turn right.
    public static let turnRight: Self = "TURN_RIGHT"
    /// Sharp left.
    public static let sharpLeft: Self = "SHARP_LEFT"
    /// Sharp right.
    public static let sharpRight: Self = "SHARP_RIGHT"
    /// Slight left.
    public static let slightLeft: Self = "SLIGHT_LEFT"
    /// Slight right.
    public static let slightRight: Self = "SLIGHT_RIGHT"
    /// Continue straight.
    public static let `continue`: Self = "CONTINUE"
    /// Enter a roundabout.
    public static let enterRoundabout: Self = "ENTER_ROUNDABOUT"
    /// Exit a roundabout.
    public static let exitRoundabout: Self = "EXIT_ROUNDABOUT"
    /// Make a U-turn.
    public static let uturn: Self = "UTURN"
    /// Arrive at the destination.
    public static let goal: Self = "GOAL"
    /// Depart from the start.
    public static let depart: Self = "DEPART"
    /// Keep left.
    public static let keepLeft: Self = "KEEP_LEFT"
    /// Keep right.
    public static let keepRight: Self = "KEEP_RIGHT"
    /// Unknown or unclassified maneuver.
    public static let unknown: Self = "UNKNOWN"

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
