// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Surface, way type, and steepness analysis result for a geometry.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct GeometryAnalysis: Sendable, Hashable, Codable {
    /// Elevation summary over the analyzed geometry, including altitude bounds, total
    /// elevation gain/loss, and gradient extremes.
    public var elevation: DataSchema.ElevationSummary?
    /// Elevation in meters above sea level, one value per vertex, in order: per input
    /// coordinate for `analyzeGeometry`, and per vertex of the returned route geometry
    /// for `directions` and `suggestions`. Lets the client build a 3D version of the
    /// line for an elevation profile. A vertex beyond 85.0511 degrees of latitude,
    /// north or south, lies past the elevation source's coverage: it reads 0, which
    /// is no data rather than an altitude, and is left out of the ascent, descent,
    /// altitude, gradient and slope figures, which describe the covered part alone.
    public var elevations: [Double]?
    /// Slope angle segments along the geometry in degrees, referencing coordinate indices.
    public var slopeInfo: [DataSchema.SlopeInfo]?
    /// Resolved travel speed segments along the geometry in km/h, referencing
    /// coordinate indices.
    ///
    /// This is the per-stretch speed the duration was integrated over, so summing
    /// each stretch's length divided by its value reproduces the duration exactly.
    /// The model slows a climb, speeds a descent, and charges for a coarse surface or
    /// a technical trail; an unanalysed stretch is charged for neither.
    public var speedInfo: [DataSchema.SpeedInfo]?
    /// Surface type segments along the geometry, referencing coordinate indices.
    /// `analyzeGeometry` covers a stretch it has no data for, or one the routing
    /// engine failed on (which `errors` then flags), with one UNKNOWN segment.
    /// Empty for the activities that carry no surface, way type or trail difficulty
    /// analysis: the four winter activities (BACKCOUNTRY_SKIING, SKI_TOURING,
    /// CROSS_COUNTRY_SKIING and SNOWSHOE_WALKING).
    public var surfaceInfo: [DataSchema.SurfaceInfo]?
    /// Trail difficulty segments along the geometry, referencing coordinate indices.
    /// Graded on the SAC hiking scale for walking activities and the mountain-biking
    /// scale for cycling ones. `analyzeGeometry` covers a stretch it has no data for,
    /// or one the routing engine failed on (which `errors` then flags), with one
    /// UNKNOWN segment. Empty for the activities with no analysis (see
    /// surfaceInfo), and on a route whose routing graph carries no trail-difficulty
    /// data.
    public var trailDifficultyInfo: [DataSchema.TrailDifficultyInfo]?
    /// Way type segments along the geometry, referencing coordinate indices.
    /// `analyzeGeometry` covers a stretch it has no data for, or one the routing
    /// engine failed on (which `errors` then flags), with one UNKNOWN segment.
    /// Empty for the activities with no analysis (see surfaceInfo).
    public var wayTypeInfo: [DataSchema.WayTypeInfo]?
    /// Route-level hazards the analyzed geometry crosses: tollways and
    /// access-restricted ways. For `analyzeGeometry` this is the union over the whole
    /// geometry, so a hazard anywhere along it raises the flag. Both flags are false
    /// and both lists empty for the activities with no analysis (see surfaceInfo)
    /// under `analyzeGeometry`, and when the activity cannot be routed at all.
    public var advisories: DataSchema.RouteAdvisories?

    /// Creates a `GeometryAnalysis` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.elevation = nil
      self.elevations = nil
      self.slopeInfo = nil
      self.speedInfo = nil
      self.surfaceInfo = nil
      self.trailDifficultyInfo = nil
      self.wayTypeInfo = nil
      self.advisories = nil
      configure(&self)
    }

    /// Reads a `GeometryAnalysis` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.elevation = try container.decodeIfPresent(
        DataSchema.ElevationSummary.self, forKey: "elevation")
      self.elevations = try container.decodeIfPresent([Double].self, forKey: "elevations")
      self.slopeInfo = try container.decodeIfPresent(
        [DataSchema.SlopeInfo].self, forKey: "slopeInfo")
      self.speedInfo = try container.decodeIfPresent(
        [DataSchema.SpeedInfo].self, forKey: "speedInfo")
      self.surfaceInfo = try container.decodeIfPresent(
        [DataSchema.SurfaceInfo].self, forKey: "surfaceInfo")
      self.trailDifficultyInfo = try container.decodeIfPresent(
        [DataSchema.TrailDifficultyInfo].self, forKey: "trailDifficultyInfo")
      self.wayTypeInfo = try container.decodeIfPresent(
        [DataSchema.WayTypeInfo].self, forKey: "wayTypeInfo")
      self.advisories = try container.decodeIfPresent(
        DataSchema.RouteAdvisories.self, forKey: "advisories")
    }

    /// Writes a `GeometryAnalysis` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.elevation, forKey: "elevation")
      try container.encodeIfPresent(self.elevations, forKey: "elevations")
      try container.encodeIfPresent(self.slopeInfo, forKey: "slopeInfo")
      try container.encodeIfPresent(self.speedInfo, forKey: "speedInfo")
      try container.encodeIfPresent(self.surfaceInfo, forKey: "surfaceInfo")
      try container.encodeIfPresent(self.trailDifficultyInfo, forKey: "trailDifficultyInfo")
      try container.encodeIfPresent(self.wayTypeInfo, forKey: "wayTypeInfo")
      try container.encodeIfPresent(self.advisories, forKey: "advisories")
    }
  }
}
