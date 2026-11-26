// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for a terrain profile along a geometry.
  public struct TerrainProfileInput: Sendable, Hashable, Codable {
    /// Ordered list of [longitude, latitude] coordinate pairs forming the geometry (WGS 84).
    /// Between 2 and 10,000 positions; any other count is VALIDATION_FAILED at
    /// ["input", "coordinates"]. Each is exactly two numbers, a longitude between -180
    /// and 180 and a latitude between -90 and 90, and one that is not is
    /// VALIDATION_FAILED at ["input", "coordinates", i]. The line, measured along its
    /// positions, is at most 500 km long, and its samples fall in at most 256
    /// distinct elevation tiles at zoom 14, counted from the laid-out samples before
    /// any is fetched; a line past either is VALIDATION_FAILED at
    /// ["input", "coordinates"], before any elevation is read.
    /// Example: [[6.8667, 45.9195], [6.8712, 45.9231], [6.8790, 45.9160]] (a short trail segment).
    public var coordinates: [[Double]]
    /// Target sampling interval along the geometry in meters. Must be between 10 and
    /// 1000 (VALIDATION_FAILED at ["input", "spacingMeters"] otherwise).
    ///
    /// It is a target, not a guarantee, in both directions. Every input vertex is
    /// retained, so the interval across a bend is SHORTER; and a line long enough to
    /// need more than 2,000 samples between its vertices is sampled at a coarser
    /// interval, so one profile holds at most 12,000 samples. Read each sample's own
    /// distanceMeters rather than assuming the interval.
    public var spacingMeters: Double?

    /// Creates a `TerrainProfileInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      coordinates: [[Double]],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.coordinates = coordinates
      self.spacingMeters = nil
      configure(&self)
    }

    /// Reads a `TerrainProfileInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.coordinates = try container.decode([[Double]].self, forKey: "coordinates")
      self.spacingMeters = try container.decodeIfPresent(Double.self, forKey: "spacingMeters")
    }

    /// Writes a `TerrainProfileInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.coordinates, forKey: "coordinates")
      try container.encodeIfPresent(self.spacingMeters, forKey: "spacingMeters")
    }
  }
}
