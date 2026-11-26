// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One server-computed mode option for a proposed import segment: either the
  /// routed (directions) reproduction or the faithful (linestring) reproduction of
  /// a source sub-track. Carries the defining geometry plus every geometry-derived
  /// metric, mirroring the persisted segment shape so a reviewer sees what a
  /// confirmed segment would carry. The confirm step recomputes every metric
  /// itself, and routes a `directions` segment again, whether or not the
  /// recommendation was accepted unchanged.
  public struct ProposedCandidate: Sendable, Hashable, Codable {
    /// How the segment's path is defined, which decides what `geojson` must
    /// carry: `directions` routes between the waypoints of a MultiPoint,
    /// `linestring` keeps the drawn line rather than routing it.
    public var mode: RestSchema.SegmentMode
    /// GeoJSON Geometry for this candidate. For directions it is the canonical
    /// GeometryCollection of the routed LineString plus the waypoint MultiPoint;
    /// for linestring it is the source's line, simplified to remove GPS jitter
    /// and resampled for its elevation profile, and it is a GeometryCollection
    /// holding that LineString and the source's own vertices as a MultiPoint
    /// when the resampling added points and those vertices number fewer than
    /// the line's sample budget `ItinerarySegment.geojson` states. Any other
    /// line, a dense recorded track among them, is the bare resampled
    /// LineString.
    public var geojson: RestSchema.GeoJSONGeometry
    /// Candidate distance in meters. Null when not computed.
    public var distance: Double?
    /// Candidate duration in seconds, computed from the geometry at the
    /// segment's `speed` when the source's timestamps gave one, and at the
    /// activity's default speed otherwise. Null when not computed.
    public var duration: Double?
    /// Total elevation gain along the candidate, in meters. Null when the
    /// geometry has no elevation data (2D) or the metric was not computed.
    public var ascent: Int?
    /// Total elevation loss along the candidate, in meters. Null when the
    /// geometry has no elevation data (2D) or the metric was not computed.
    public var descent: Int?
    /// Lowest altitude reached on the candidate, in meters above sea level. Null
    /// when the geometry has no elevation data (2D) or the metric was not
    /// computed.
    public var altitude_min: Int?
    /// Highest altitude reached on the candidate, in meters above sea level. Null
    /// when the geometry has no elevation data (2D) or the metric was not
    /// computed.
    public var altitude_max: Int?
    /// Steepest descending gradient on the candidate, in degrees (negative). Null
    /// when the geometry has no elevation data (2D) or the metric was not
    /// computed. Bounded the way `gradient_max` is, and for the same reason.
    public var gradient_min: Double?
    /// Steepest ascending gradient on the candidate, in degrees (positive). Null
    /// when the geometry has no elevation data (2D) or the metric was not
    /// computed. Degrees rather than a percentage, so the range is open at both
    /// ends of the vertical: 90 would be a cliff face and no terrain reaches it.
    public var gradient_max: Double?
    /// Slope angle stretches along the candidate geometry in degrees. Each entry
    /// references a coordinate index range. Null when the metric was not
    /// computed, which is the case for a candidate with no elevation data. Never
    /// an empty array, matching how a persisted segment reports the same metric.
    public var slope_info: [RestSchema.SlopeInfo]?
    /// Surface type stretches along the candidate geometry. Each entry references
    /// a coordinate index range. Null when the routing graph carries no surface
    /// data or the metric was not computed. Never an empty array, matching how a
    /// persisted segment reports the same metric.
    public var surface_info: [RestSchema.SurfaceInfo]?
    /// Trail difficulty stretches along the candidate geometry, graded on the SAC
    /// hiking scale for walking activities and the mountain-biking scale for
    /// cycling ones. Each entry references a coordinate index range. Null when
    /// the routing graph carries no trail-difficulty data or the metric was not
    /// computed. Never an empty array, matching how a persisted segment reports
    /// the same metric.
    public var trail_difficulty_info: [RestSchema.TrailDifficultyInfo]?
    /// Way type stretches along the candidate geometry. Each entry references a
    /// coordinate index range. Null when the routing graph carries no way-type
    /// data or the metric was not computed. Never an empty array, matching how a
    /// persisted segment reports the same metric.
    public var way_type_info: [RestSchema.WayTypeInfo]?

    /// Creates a `ProposedCandidate` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      mode: RestSchema.SegmentMode,
      geojson: RestSchema.GeoJSONGeometry,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.mode = mode
      self.geojson = geojson
      self.distance = nil
      self.duration = nil
      self.ascent = nil
      self.descent = nil
      self.altitude_min = nil
      self.altitude_max = nil
      self.gradient_min = nil
      self.gradient_max = nil
      self.slope_info = nil
      self.surface_info = nil
      self.trail_difficulty_info = nil
      self.way_type_info = nil
      configure(&self)
    }

    /// Reads a `ProposedCandidate` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.mode = try container.decode(RestSchema.SegmentMode.self, forKey: "mode")
      self.geojson = try container.decode(RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.duration = try container.decodeIfPresent(Double.self, forKey: "duration")
      self.ascent = try container.decodeIfPresent(Int.self, forKey: "ascent")
      self.descent = try container.decodeIfPresent(Int.self, forKey: "descent")
      self.altitude_min = try container.decodeIfPresent(Int.self, forKey: "altitude_min")
      self.altitude_max = try container.decodeIfPresent(Int.self, forKey: "altitude_max")
      self.gradient_min = try container.decodeIfPresent(Double.self, forKey: "gradient_min")
      self.gradient_max = try container.decodeIfPresent(Double.self, forKey: "gradient_max")
      self.slope_info = try container.decodeIfPresent(
        [RestSchema.SlopeInfo].self, forKey: "slope_info")
      self.surface_info = try container.decodeIfPresent(
        [RestSchema.SurfaceInfo].self, forKey: "surface_info")
      self.trail_difficulty_info = try container.decodeIfPresent(
        [RestSchema.TrailDifficultyInfo].self, forKey: "trail_difficulty_info")
      self.way_type_info = try container.decodeIfPresent(
        [RestSchema.WayTypeInfo].self, forKey: "way_type_info")
    }

    /// Writes a `ProposedCandidate` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.geojson, forKey: "geojson")
      try container.encodeIfPresent(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.duration, forKey: "duration")
      try container.encodeIfPresent(self.ascent, forKey: "ascent")
      try container.encodeIfPresent(self.descent, forKey: "descent")
      try container.encodeIfPresent(self.altitude_min, forKey: "altitude_min")
      try container.encodeIfPresent(self.altitude_max, forKey: "altitude_max")
      try container.encodeIfPresent(self.gradient_min, forKey: "gradient_min")
      try container.encodeIfPresent(self.gradient_max, forKey: "gradient_max")
      try container.encodeIfPresent(self.slope_info, forKey: "slope_info")
      try container.encodeIfPresent(self.surface_info, forKey: "surface_info")
      try container.encodeIfPresent(self.trail_difficulty_info, forKey: "trail_difficulty_info")
      try container.encodeIfPresent(self.way_type_info, forKey: "way_type_info")
    }
  }
}
