// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for analyzing surface and way type of an existing geometry.
  public struct AnalyzeGeometryInput: Sendable, Hashable, Codable {
    /// Activity to use for analysis.
    public var activity: DataSchema.ActivitySlug
    /// Ordered list of [longitude, latitude] coordinate pairs forming the geometry (WGS 84).
    /// Between 2 and 10,000 positions; a count outside that range is VALIDATION_FAILED
    /// at ["input", "coordinates"]. The line, measured along its positions, is at
    /// most 500 km long; a longer one is VALIDATION_FAILED at
    /// ["input", "coordinates"], decided before any elevation or routing work. Each
    /// is exactly two numbers, a longitude between -180 and 180 and a latitude
    /// between -90 and 90, and one that is not is VALIDATION_FAILED at
    /// ["input", "coordinates", i].
    /// Example: [[6.8667, 45.9195], [6.8712, 45.9231], [6.8790, 45.9160]] (a short trail segment).
    public var coordinates: [[Double]]
    /// Travel speed in km/h on LEVEL ground, a finite number greater than 0 (anything
    /// else, NaN and Infinity included, is VALIDATION_FAILED at ["input", "speed"],
    /// never answered at the activity default), replacing the activity's default as
    /// the pace `duration` is anchored to. Omitted uses the activity default. Each
    /// stretch's resolved speed is capped at the activity's maximum speed (see
    /// SpeedInfo).
    ///
    /// It is the same field, meaning the same thing, that `directions` and
    /// `suggestions` take, which is the point of it being here. A drawn line
    /// previewed at the pace it will be saved at and the segment it becomes report
    /// the same duration; without it, analyzing a line could only ever answer at the
    /// activity default while the saved segment answered at the user's speed.
    /// Example: 4.5 for hiking, 25.0 for road cycling.
    public var speed: Double?

    /// Creates a `AnalyzeGeometryInput` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      activity: DataSchema.ActivitySlug,
      coordinates: [[Double]],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.activity = activity
      self.coordinates = coordinates
      self.speed = nil
      configure(&self)
    }

    /// Reads a `AnalyzeGeometryInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.activity = try container.decode(DataSchema.ActivitySlug.self, forKey: "activity")
      self.coordinates = try container.decode([[Double]].self, forKey: "coordinates")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
    }

    /// Writes a `AnalyzeGeometryInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.activity, forKey: "activity")
      try container.encode(self.coordinates, forKey: "coordinates")
      try container.encodeIfPresent(self.speed, forKey: "speed")
    }
  }
}
