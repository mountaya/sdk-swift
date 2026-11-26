// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// One segment of an itinerary: a single routed or drawn leg, with its geometry and
  /// the elevation figures computed for it.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ItinerarySegment: Sendable, Hashable, Codable {
    /// Segment identifier.
    public var id: String?
    /// Display name of the segment. Example: "Day 1".
    public var name: String?
    /// Free-text description of the segment. Null when it has none.
    public var description: String?
    /// Zero-based position of the segment within the itinerary's ordered chain.
    public var position: Int?
    /// Identifier of the segment group this segment belongs to, matching an entry of the
    /// itinerary's `groups`; null when the segment belongs to none. Grouping is
    /// presentation only and never changes the segment itself.
    public var groupId: String?
    /// Segment distance in meters; null when the segment has not been computed.
    public var distance: Double?
    /// Segment duration in seconds; null when the segment has not been computed.
    public var duration: Double?
    /// Elevation gain along the segment in meters; null when unknown.
    public var ascent: Int?
    /// Elevation loss along the segment in meters; null when unknown.
    public var descent: Int?
    /// Altitude range along the segment in meters above sea level; null when the segment
    /// carries no elevation data.
    public var altitude: DataSchema.MetricRange?
    /// Gradient range along the segment in degrees, positive uphill and negative
    /// downhill; null when the segment carries no elevation data.
    public var gradient: DataSchema.MetricRange?
    /// GeoJSON Geometry object for the segment path; null when the segment has no
    /// geometry yet. It is one of two shapes. A drawn segment is a bare LineString,
    /// simplified and resampled to about one position every 50 m. A routed segment
    /// is a GeometryCollection holding the routed LineString and a MultiPoint of
    /// the waypoints it was routed through, and so is a drawn one when resampling
    /// added positions between the vertices it was drawn with and those vertices
    /// number fewer than its sample budget, one position per 50 m of its distance
    /// plus two, never fewer than 400 and never more than 4,000: its MultiPoint
    /// then holds the vertices drawn. A dense recorded track is therefore a bare
    /// LineString even where resampling filled a gap in it. A collection of one
    /// member is never sent.
    ///
    /// Each position is [longitude, latitude, altitude] once the segment's
    /// elevation has been read, and [longitude, latitude] otherwise. To reason
    /// about the ground the segment covers with terrainProfile or analyzeGeometry,
    /// take the LineString, the geometry itself or the collection's LineString
    /// member, and send its positions reduced to [longitude, latitude] as their
    /// `coordinates`: both take exactly two numbers per position and at most
    /// 10,000 positions, so a longer line is sent in parts.
    public var geometry: GeoJSONGeometry?

    /// Creates a `ItinerarySegment` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.name = nil
      self.description = nil
      self.position = nil
      self.groupId = nil
      self.distance = nil
      self.duration = nil
      self.ascent = nil
      self.descent = nil
      self.altitude = nil
      self.gradient = nil
      self.geometry = nil
      configure(&self)
    }

    /// Reads a `ItinerarySegment` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.position = try container.decodeIfPresent(Int.self, forKey: "position")
      self.groupId = try container.decodeIfPresent(String.self, forKey: "groupId")
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.duration = try container.decodeIfPresent(Double.self, forKey: "duration")
      self.ascent = try container.decodeIfPresent(Int.self, forKey: "ascent")
      self.descent = try container.decodeIfPresent(Int.self, forKey: "descent")
      self.altitude = try container.decodeIfPresent(DataSchema.MetricRange.self, forKey: "altitude")
      self.gradient = try container.decodeIfPresent(DataSchema.MetricRange.self, forKey: "gradient")
      self.geometry = try container.decodeIfPresent(GeoJSONGeometry.self, forKey: "geometry")
    }

    /// Writes a `ItinerarySegment` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.position, forKey: "position")
      try container.encodeIfPresent(self.groupId, forKey: "groupId")
      try container.encodeIfPresent(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.duration, forKey: "duration")
      try container.encodeIfPresent(self.ascent, forKey: "ascent")
      try container.encodeIfPresent(self.descent, forKey: "descent")
      try container.encodeIfPresent(self.altitude, forKey: "altitude")
      try container.encodeIfPresent(self.gradient, forKey: "gradient")
      try container.encodeIfPresent(self.geometry, forKey: "geometry")
    }
  }
}
