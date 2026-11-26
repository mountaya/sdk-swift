// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single computed route with distance, duration, elevation, geometry, and
  /// analysis.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct DirectionsRoute: Sendable, Hashable, Codable {
    /// Total route distance in meters, measured as the planimetric great-circle
    /// length of the geometry field, with elevation ignored.
    /// Example: 15200.0 for a 15.2 km route.
    public var distance: Double?
    /// Estimated route duration in seconds, computed over the terrain the route
    /// crosses rather than over its distance: the model charges for grade, surface
    /// and trail difficulty edge by edge, anchored on the requested `speed` (or the
    /// activity default) as the pace on level ground. Integrating
    /// `analysis.speedInfo` over the geometry reproduces this number exactly.
    /// Example: 18720.0 for a 5h12m route.
    public var duration: Double?
    /// Elevation summary including altitude bounds, total gain/loss, and gradient
    /// extremes.
    public var elevation: DataSchema.ElevationSummary?
    /// GeoJSON geometry representing the route path.
    public var geometry: GeoJSONGeometry?
    /// Surface and way type analysis for the route geometry, including the
    /// `advisories` naming any tollway or access-restricted way it crosses.
    public var analysis: DataSchema.GeometryAnalysis?
    /// What the request's `avoid` list achieved for this route. NOT_REQUESTED when
    /// none was given.
    public var avoidance: DataSchema.AvoidanceOutcome?
    /// Human-readable route summary.
    /// Example: "15.2 km, ~4h12m, +720m / -430m elevation, 62% path, 28% track."
    public var summary: String?
    /// Turn-by-turn direction steps along the route, in travel order.
    public var steps: [DataSchema.DirectionsStep]?

    /// Creates a `DirectionsRoute` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.distance = nil
      self.duration = nil
      self.elevation = nil
      self.geometry = nil
      self.analysis = nil
      self.avoidance = nil
      self.summary = nil
      self.steps = nil
      configure(&self)
    }

    /// Reads a `DirectionsRoute` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.duration = try container.decodeIfPresent(Double.self, forKey: "duration")
      self.elevation = try container.decodeIfPresent(
        DataSchema.ElevationSummary.self, forKey: "elevation")
      self.geometry = try container.decodeIfPresent(GeoJSONGeometry.self, forKey: "geometry")
      self.analysis = try container.decodeIfPresent(
        DataSchema.GeometryAnalysis.self, forKey: "analysis")
      self.avoidance = try container.decodeIfPresent(
        DataSchema.AvoidanceOutcome.self, forKey: "avoidance")
      self.summary = try container.decodeIfPresent(String.self, forKey: "summary")
      self.steps = try container.decodeIfPresent([DataSchema.DirectionsStep].self, forKey: "steps")
    }

    /// Writes a `DirectionsRoute` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.duration, forKey: "duration")
      try container.encodeIfPresent(self.elevation, forKey: "elevation")
      try container.encodeIfPresent(self.geometry, forKey: "geometry")
      try container.encodeIfPresent(self.analysis, forKey: "analysis")
      try container.encodeIfPresent(self.avoidance, forKey: "avoidance")
      try container.encodeIfPresent(self.summary, forKey: "summary")
      try container.encodeIfPresent(self.steps, forKey: "steps")
    }
  }
}
