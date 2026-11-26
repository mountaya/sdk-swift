// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for computing isochrones.
  public struct IsochronesInput: Sendable, Hashable, Codable {
    /// Activity to use for routing. BACKCOUNTRY_SKIING has no routing, and
    /// GRAVEL_BIKE and MOUNTAIN_BIKE are unavailable: all three are
    /// VALIDATION_FAILED at ["input", "activity"].
    public var activity: DataSchema.ActivitySlug
    /// Starting locations as [longitude, latitude] coordinate pairs (WGS 84), one
    /// or two (none, or more than two, is VALIDATION_FAILED at
    /// ["input", "locations"]). Each is exactly two numbers, a longitude between -180 and 180 and a
    /// latitude between -90 and 90, and one that is not is VALIDATION_FAILED at
    /// ["input", "locations", i]. Each location is placed on the activity's network
    /// as a `directions` waypoint is, within the same radius (400 meters for most
    /// activities) and on the ways the activity routes on, so a way it avoids, a
    /// ferry line for one, never places it. A location no such way lies near is
    /// VALIDATION_FAILED at ["input", "locations", i], one entry per such location:
    /// a point in a lake or out at sea, for example.
    /// Example: [[6.8712, 45.9231]] (single origin at Chamonix).
    public var locations: [[Double]]
    /// Range values in seconds (TIME) or meters (DISTANCE), one to six (none, or
    /// more than six, is VALIDATION_FAILED at ["input", "range"]). Each is greater
    /// than zero and at most 7,200 seconds or 25,000 meters, and one that is not is
    /// VALIDATION_FAILED at ["input", "range", i]. Multiple values produce
    /// concentric isochrones.
    /// Example: [600, 1200, 1800] for 10, 20, 30 minute isochrones (TIME).
    /// Example: [5000, 10000] for 5 km and 10 km isochrones (DISTANCE).
    public var range: [Double]
    /// Whether the range is expressed in time or distance.
    ///
    /// A TIME budget is measured with the routing engine's own travel-time model,
    /// not the terrain-aware model behind `duration` on `directions`, `suggestions`
    /// and `analyzeGeometry`, so an isochrone's edge and a route's duration are not
    /// interchangeable figures.
    public var rangeType: DataSchema.RangeType
    /// Travel speed in km/h, a finite number greater than 0 (anything else, NaN and
    /// Infinity included, is VALIDATION_FAILED at ["input", "speed"]). When
    /// provided, the time budget is stretched by the ratio of this pace to the
    /// routing engine's own pace for the activity, 5 km/h for the activities on foot
    /// and on skis and 20 km/h for ROAD_CYCLING, so the polygon covers the ground
    /// this pace reaches within the requested range. The stretched budget is held to
    /// the same 7,200 seconds as a range: a speed that takes any range value past it,
    /// once multiplied by that ratio, is VALIDATION_FAILED at ["input", "speed"]. At
    /// 10 km/h on foot, for example, every range value must be at most 3,600 seconds.
    /// Only meaningful when rangeType is TIME: a distance range is speed-independent,
    /// and pairing the two is VALIDATION_FAILED at ["input", "speed"].
    public var speed: Double?

    /// Creates a `IsochronesInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      activity: DataSchema.ActivitySlug,
      locations: [[Double]],
      range: [Double],
      rangeType: DataSchema.RangeType,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.activity = activity
      self.locations = locations
      self.range = range
      self.rangeType = rangeType
      self.speed = nil
      configure(&self)
    }

    /// Reads a `IsochronesInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.activity = try container.decode(DataSchema.ActivitySlug.self, forKey: "activity")
      self.locations = try container.decode([[Double]].self, forKey: "locations")
      self.range = try container.decode([Double].self, forKey: "range")
      self.rangeType = try container.decode(DataSchema.RangeType.self, forKey: "rangeType")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
    }

    /// Writes a `IsochronesInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.activity, forKey: "activity")
      try container.encode(self.locations, forKey: "locations")
      try container.encode(self.range, forKey: "range")
      try container.encode(self.rangeType, forKey: "rangeType")
      try container.encodeIfPresent(self.speed, forKey: "speed")
    }
  }
}
