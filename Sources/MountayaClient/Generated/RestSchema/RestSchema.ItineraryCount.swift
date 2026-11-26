// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Aggregate counts for an itinerary.
  public struct ItineraryCount: Sendable, Hashable, Codable {
    /// Total number of segment groups defined on the itinerary.
    public var groups: Int
    /// Total number of segments in the itinerary.
    public var segments: Int
    /// Total number of waypoints in the itinerary.
    public var waypoints: Int

    /// Creates a `ItineraryCount` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      groups: Int,
      segments: Int,
      waypoints: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.groups = groups
      self.segments = segments
      self.waypoints = waypoints
      configure(&self)
    }

    /// Reads a `ItineraryCount` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.groups = try container.decode(Int.self, forKey: "groups")
      self.segments = try container.decode(Int.self, forKey: "segments")
      self.waypoints = try container.decode(Int.self, forKey: "waypoints")
    }

    /// Writes a `ItineraryCount` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.groups, forKey: "groups")
      try container.encode(self.segments, forKey: "segments")
      try container.encode(self.waypoints, forKey: "waypoints")
    }
  }
}
