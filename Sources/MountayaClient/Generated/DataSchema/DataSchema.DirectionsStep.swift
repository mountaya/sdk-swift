// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single turn-by-turn direction step referencing a coordinate index range on
  /// the route geometry (same index basis as SurfaceInfo/WayTypeInfo/SlopeInfo).
  /// Shared leaf type for both DirectionsRoute and SuggestionRoute.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct DirectionsStep: Sendable, Hashable, Codable {
    /// Start index in the route coordinates array (inclusive).
    public var fromIndex: Int?
    /// End index in the route coordinates array (inclusive).
    public var toIndex: Int?
    /// Maneuver to perform at the start of this step.
    public var type: DataSchema.ManeuverType?
    /// Name of the way/street for this step. May be empty or "-" when unnamed.
    public var name: String?
    /// Length of this step in meters: the routing engine's figure for the step,
    /// rescaled by the factor that takes the engine's own route length to the route's
    /// measured `distance`.
    public var distance: Double?
    /// Estimated duration of this step in seconds, from the same travel-time model as
    /// the route's `duration`, over the step's stretch of the geometry.
    public var duration: Double?
    /// For a roundabout maneuver, the 1-based exit to take. Null for any other
    /// maneuver, matching `exit_number` on the REST resource, which is nullable for
    /// the same reason.
    public var exitNumber: Int?

    /// Creates a `DirectionsStep` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.fromIndex = nil
      self.toIndex = nil
      self.type = nil
      self.name = nil
      self.distance = nil
      self.duration = nil
      self.exitNumber = nil
      configure(&self)
    }

    /// Reads a `DirectionsStep` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.fromIndex = try container.decodeIfPresent(Int.self, forKey: "fromIndex")
      self.toIndex = try container.decodeIfPresent(Int.self, forKey: "toIndex")
      self.type = try container.decodeIfPresent(DataSchema.ManeuverType.self, forKey: "type")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.duration = try container.decodeIfPresent(Double.self, forKey: "duration")
      self.exitNumber = try container.decodeIfPresent(Int.self, forKey: "exitNumber")
    }

    /// Writes a `DirectionsStep` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.fromIndex, forKey: "fromIndex")
      try container.encodeIfPresent(self.toIndex, forKey: "toIndex")
      try container.encodeIfPresent(self.type, forKey: "type")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.duration, forKey: "duration")
      try container.encodeIfPresent(self.exitNumber, forKey: "exitNumber")
    }
  }
}
