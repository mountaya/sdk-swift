// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A single turn-by-turn direction step along a routed (directions-mode) segment.
  /// from_index / to_index reference the segment geometry's coordinate array, the
  /// same index basis as slope_info, surface_info, and way_type_info. Steps are
  /// computed when the segment is routed and returned with it; a linestring segment
  /// has none.
  public struct ItineraryDirectionsStep: Sendable, Hashable, Codable {
    /// Length of this step in meters.
    public var distance: Double
    /// Estimated duration of this step in seconds.
    public var duration: Double
    /// For a roundabout maneuver, the 1-based exit to take. Null for any other
    /// maneuver.
    public var exit_number: Int?
    /// Start index in the segment coordinates array (inclusive).
    public var from_index: Int
    /// Name of the way or street for this step. May be empty or "-" when the way
    /// is unnamed.
    public var name: String
    /// End index in the segment coordinates array (inclusive).
    public var to_index: Int
    /// The maneuver this step asks for, which is what a turn-by-turn renderer
    /// picks its icon and its phrasing from. `unknown` is a real member: a
    /// provider that returns a maneuver outside the set lands there rather than
    /// dropping the step.
    public var type: RestSchema.ManeuverType

    /// Creates a `ItineraryDirectionsStep` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      distance: Double,
      duration: Double,
      exit_number: Int?,
      from_index: Int,
      name: String,
      to_index: Int,
      type: RestSchema.ManeuverType,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.distance = distance
      self.duration = duration
      self.exit_number = exit_number
      self.from_index = from_index
      self.name = name
      self.to_index = to_index
      self.type = type
      configure(&self)
    }

    /// Reads a `ItineraryDirectionsStep` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.distance = try container.decode(Double.self, forKey: "distance")
      self.duration = try container.decode(Double.self, forKey: "duration")
      self.exit_number = try container.decodeIfPresent(Int.self, forKey: "exit_number")
      self.from_index = try container.decode(Int.self, forKey: "from_index")
      self.name = try container.decode(String.self, forKey: "name")
      self.to_index = try container.decode(Int.self, forKey: "to_index")
      self.type = try container.decode(RestSchema.ManeuverType.self, forKey: "type")
    }

    /// Writes a `ItineraryDirectionsStep` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.distance, forKey: "distance")
      try container.encode(self.duration, forKey: "duration")
      try container.encodeNullable(self.exit_number, forKey: "exit_number")
      try container.encode(self.from_index, forKey: "from_index")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.to_index, forKey: "to_index")
      try container.encode(self.type, forKey: "type")
    }
  }
}
