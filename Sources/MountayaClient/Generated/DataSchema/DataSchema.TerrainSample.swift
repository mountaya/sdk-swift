// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single surface reading. Shared by all three terrain queries.
  ///
  /// A reading is reported as outside DEM coverage, with a null elevation, slope and
  /// aspect, both when the point lies beyond the DEM and when the DEM tile holding it
  /// could not be fetched. A query fails with INTERNAL_ERROR only when no tile at all
  /// could be fetched.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct TerrainSample: Sendable, Hashable, Codable {
    /// Echo of the sampled [longitude, latitude] point (WGS 84).
    public var point: [Double]?
    /// Elevation in meters above sea level; null when the point falls outside DEM
    /// coverage.
    public var elevation: Double?
    /// Slope angle in degrees; null when the point falls outside DEM coverage.
    public var slope: Double?
    /// Downhill aspect as a compass bearing in degrees (0-360, 0 = north); null when
    /// the point falls outside DEM coverage or the surface is flat.
    public var aspect: Double?
    /// Compass octant of the downhill aspect; null whenever aspect is null.
    public var aspectOctant: DataSchema.AspectOctant?
    /// Steepness band derived from the slope, matching the steepness overlay's legend;
    /// null below 25 degrees or outside DEM coverage.
    public var steepnessBand: DataSchema.SteepnessBand?
    /// Distance along the geometry from its start, in meters; null outside a
    /// terrainProfile result.
    ///
    /// It is carried per sample rather than implied by the index because
    /// `spacingMeters` is a target, not a constant: every input vertex is retained, so
    /// a sample immediately after a bend sits closer than the interval, and a very long
    /// line is sampled more coarsely. Multiplying the index by the spacing would place
    /// every sample after the first bend in the wrong place.
    public var distanceMeters: Double?

    /// Creates a `TerrainSample` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.point = nil
      self.elevation = nil
      self.slope = nil
      self.aspect = nil
      self.aspectOctant = nil
      self.steepnessBand = nil
      self.distanceMeters = nil
      configure(&self)
    }

    /// Reads a `TerrainSample` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.point = try container.decodeIfPresent([Double].self, forKey: "point")
      self.elevation = try container.decodeIfPresent(Double.self, forKey: "elevation")
      self.slope = try container.decodeIfPresent(Double.self, forKey: "slope")
      self.aspect = try container.decodeIfPresent(Double.self, forKey: "aspect")
      self.aspectOctant = try container.decodeIfPresent(
        DataSchema.AspectOctant.self, forKey: "aspectOctant")
      self.steepnessBand = try container.decodeIfPresent(
        DataSchema.SteepnessBand.self, forKey: "steepnessBand")
      self.distanceMeters = try container.decodeIfPresent(Double.self, forKey: "distanceMeters")
    }

    /// Writes a `TerrainSample` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.elevation, forKey: "elevation")
      try container.encodeIfPresent(self.slope, forKey: "slope")
      try container.encodeIfPresent(self.aspect, forKey: "aspect")
      try container.encodeIfPresent(self.aspectOctant, forKey: "aspectOctant")
      try container.encodeIfPresent(self.steepnessBand, forKey: "steepnessBand")
      try container.encodeIfPresent(self.distanceMeters, forKey: "distanceMeters")
    }
  }
}
