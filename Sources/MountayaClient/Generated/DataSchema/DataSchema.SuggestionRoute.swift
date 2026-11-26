// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single suggested route candidate with distance, duration, elevation,
  /// geometry, and analysis.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct SuggestionRoute: Sendable, Hashable, Codable {
    /// Total route distance in meters, measured as the planimetric great-circle
    /// length of the geometry field, with elevation ignored. This is measured from
    /// the candidate, so it may differ from the requested target distance.
    public var distance: Double?
    /// Estimated route duration in seconds, computed over the terrain the candidate
    /// crosses rather than over its distance, anchored on the requested `speed` (or
    /// the activity default) as the pace on level ground. Integrating
    /// `analysis.speedInfo` over the geometry reproduces this number exactly.
    public var duration: Double?
    /// Elevation summary including altitude bounds, total gain/loss, and gradient
    /// extremes.
    public var elevation: DataSchema.ElevationSummary?
    /// GeoJSON geometry representing the route path.
    public var geometry: GeoJSONGeometry?
    /// Surface and way type analysis for the route geometry. Its `advisories` raise
    /// no flag, because a candidate that crosses a tollway or an access-restricted
    /// way is never returned.
    public var analysis: DataSchema.GeometryAnalysis?
    /// Human-readable route summary.
    /// Example: "20.1 km, ~5h30m, +850m / -850m elevation, 45% path, 38% track."
    public var summary: String?
    /// Turn-by-turn direction steps along this candidate, in travel order.
    public var steps: [DataSchema.DirectionsStep]?
    /// Seed value used to generate this route candidate. Pass this seed back in
    /// SuggestionsInput.seeds.include to pin this route into a future result, or
    /// in .exclude to filter it out of the fresh candidate pool. Reproducing a
    /// route also requires passing the same start/end/distance/points as the
    /// original request. Mismatched inputs will produce a different route even
    /// with the same seed.
    public var seed: Int?

    /// Creates a `SuggestionRoute` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.distance = nil
      self.duration = nil
      self.elevation = nil
      self.geometry = nil
      self.analysis = nil
      self.summary = nil
      self.steps = nil
      self.seed = nil
      configure(&self)
    }

    /// Reads a `SuggestionRoute` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.duration = try container.decodeIfPresent(Double.self, forKey: "duration")
      self.elevation = try container.decodeIfPresent(
        DataSchema.ElevationSummary.self, forKey: "elevation")
      self.geometry = try container.decodeIfPresent(GeoJSONGeometry.self, forKey: "geometry")
      self.analysis = try container.decodeIfPresent(
        DataSchema.GeometryAnalysis.self, forKey: "analysis")
      self.summary = try container.decodeIfPresent(String.self, forKey: "summary")
      self.steps = try container.decodeIfPresent([DataSchema.DirectionsStep].self, forKey: "steps")
      self.seed = try container.decodeIfPresent(Int.self, forKey: "seed")
    }

    /// Writes a `SuggestionRoute` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.duration, forKey: "duration")
      try container.encodeIfPresent(self.elevation, forKey: "elevation")
      try container.encodeIfPresent(self.geometry, forKey: "geometry")
      try container.encodeIfPresent(self.analysis, forKey: "analysis")
      try container.encodeIfPresent(self.summary, forKey: "summary")
      try container.encodeIfPresent(self.steps, forKey: "steps")
      try container.encodeIfPresent(self.seed, forKey: "seed")
    }
  }
}
