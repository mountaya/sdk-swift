// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A segment within an itinerary, representing a single routed or freehand path.
  /// Carries its schedule, geometry, and all geometry-derived metrics. The activity
  /// is shared by the whole itinerary; segments form a connected chain ordered by
  /// their zero-based position.
  public struct ItinerarySegment: Sendable, Hashable, Codable {
    /// Highest altitude reached on the segment, in meters above sea level. Null
    /// when the segment geometry has no elevation data (2D) or when the metric
    /// was not computed.
    public var altitude_max: Int?
    /// Lowest altitude reached on the segment, in meters above sea level. Null
    /// when the segment geometry has no elevation data (2D) or when the metric
    /// was not computed.
    public var altitude_min: Int?
    /// Total elevation gain along the segment, in meters. Null when the segment
    /// geometry has no elevation data (2D) or when the metric was not computed.
    public var ascent: Int?
    /// Hex color code for rendering this segment on the map. Always the six-digit
    /// lowercase form, whichever form was written. Null when using the default
    /// activity color.
    public var color: String?
    /// Timestamp of the segment's creation.
    public var created_at: Date
    /// The user who created the segment. It is the author rather than the last
    /// editor, and it does not move when another member edits the segment.
    public var created_by: RestSchema.RelationToUser
    /// Total elevation loss along the segment, in meters. Null when the segment
    /// geometry has no elevation data (2D) or when the metric was not computed.
    public var descent: Int?
    /// Free-text description of the segment. Null when it has none.
    public var description: String?
    /// Total distance of the segment in meters, measured as the planimetric
    /// great-circle length of the geojson geometry. Elevation is ignored, and
    /// routed and freehand segments are measured identically, so summing the
    /// geometry's vertices independently reproduces this value. Null when not
    /// computed.
    public var distance: Double?
    /// Estimated travel duration of the segment in seconds, computed from the
    /// geometry and speed. Null when not computed.
    public var duration: Double?
    /// GeoJSON Geometry object representing the segment path. A `directions`
    /// segment is a GeometryCollection holding the routed LineString and a
    /// MultiPoint of the waypoints it was routed through. A `linestring` segment
    /// is the bare LineString as kept, simplified and resampled, unless
    /// resampling added positions between the vertices drawn and those vertices
    /// number fewer than the line's sample budget: one position per 50 m of its
    /// `distance`, plus two, never fewer than 400 and never more than 4,000.
    /// Then it is a GeometryCollection holding that LineString and a MultiPoint
    /// of the vertices drawn. A dense recorded track, drawn with as many
    /// vertices as its budget or more, is therefore the bare resampled
    /// LineString even where resampling filled a gap in it: a bare LineString
    /// does not say the line was never resampled. A geometry is never sent as a
    /// collection of one member.
    /// Every shape read here is one the segment writes accept, and each write
    /// reads it the way its `geojson` describes. A `directions` segment's
    /// routed LineString is stored at the full length the route was computed
    /// at, whatever its number of positions: a write reads and counts only the
    /// MultiPoint beside it, so the 10,000 positions a write takes never
    /// refuse a routed segment sent back as read. The indexes in
    /// `road_access_info`, `slope_info`, `speed_info`, `surface_info`,
    /// `trail_difficulty_info` and `way_type_info` count positions of the
    /// LineString. Null when the segment has no geometry yet.
    public var geojson: RestSchema.GeoJSONGeometry?
    /// Steepest ascending gradient on the segment, in degrees (positive). Null
    /// when the segment geometry has no elevation data (2D) or when the metric
    /// was not computed. Degrees rather than a percentage, so the range is open
    /// at both ends of the vertical: 90 would be a cliff face and no terrain
    /// reaches it.
    public var gradient_max: Double?
    /// Steepest descending gradient on the segment, in degrees (negative). Null
    /// when the segment geometry has no elevation data (2D) or when the metric
    /// was not computed. Bounded the way `gradient_max` is, and for the same
    /// reason.
    public var gradient_min: Double?
    /// Identifier of the segment group this segment belongs to, or null when it
    /// belongs to none. A group is presentation only: it overrides the name,
    /// color, and speed shown for a contiguous run of segments on the elevation
    /// profile, and never changes the segments themselves. Resolve it against the
    /// itinerary's groups array.
    public var group_id: String?
    /// Unique identifier of the segment.
    public var id: String
    /// Identifier of the parent itinerary.
    public var itinerary_id: String
    /// How the segment's path is defined, which decides what `geojson` must
    /// carry: `directions` routes between the waypoints of a MultiPoint,
    /// `linestring` keeps the drawn line rather than routing it.
    public var mode: RestSchema.SegmentMode
    /// Display name of the segment.
    public var name: String
    /// Zero-based position of the segment within its parent itinerary's chain.
    /// Always server-assigned and never accepted as an input: creating,
    /// inserting, merging, splitting, or deleting a segment renumbers the whole
    /// chain so positions stay consecutive from zero.
    ///
    /// The server writes it, and a request never sends it.
    public var position: Int
    /// Revision number of the segment, incremented on each change written to it.
    /// Dissolving a group writes none: when a group is deleted, or dissolved
    /// because a merge or a delete left it with one member, each former member's
    /// `group_id` becomes null while its `revision` stays. A consumer holding an
    /// older copy compares it with the `revision` a change frame carries; no
    /// request takes it.
    public var revision: Int
    /// The stretches of the segment geometry that follow a way carrying an
    /// access restriction, each with every restriction tagged there. Each entry
    /// references a coordinate index range. `permissive`, `agricultural` and
    /// `forestry` stretches are listed too, as information. An empty array when
    /// the geometry was analysed and no way along it carries a restriction. Null
    /// when it was never analysed: a segment with no geometry, a segment of an
    /// activity the routing engine does not classify, and, until Mountaya has
    /// analysed it, a segment stored before its access restrictions were
    /// recorded. Unlike the terrain analysis it is answered to every reader, a
    /// share token and a publishable key of an organization whose safety rules
    /// disable profile analysis included, because it is a safety notice the
    /// itinerary tiles draw as well, in their `itinerary_restrictions` source
    /// layer.
    public var road_access_info: [RestSchema.RoadAccessInfo]?
    /// Slope angle segments along the segment geometry in degrees. Each entry
    /// references a coordinate index range. Positive values indicate uphill,
    /// negative values indicate downhill. Null when the metric was never
    /// computed, which is the case for a segment with no geometry or no elevation
    /// data. Never an empty array.
    public var slope_info: [RestSchema.SlopeInfo]?
    /// Travel speed in km/h ASKED FOR on level ground: the flat pace the
    /// travel-time model starts from, not the speed actually travelled anywhere
    /// on the segment. Stored rounded to two decimal places, and at most
    /// 999.99. Null when using the activity's default. See speed_info for the
    /// speed the model resolved along the line.
    public var speed: Double?
    /// Resolved travel speed in km/h along the segment geometry. Each entry
    /// references a coordinate index range. This is the per-stretch speed the
    /// duration was integrated over, so summing each stretch's length divided by
    /// its value reproduces duration exactly: it is what the segment actually
    /// travels at there, where speed is only the flat pace it started from. The
    /// model slows a climb, speeds a descent, and charges for a coarse surface or
    /// a technical trail. Null when the metric was never computed, which is the
    /// case for a segment with no geometry or no elevation data. Never an empty
    /// array; `ItineraryPaceSegment.speed_info` is the other way round, and says
    /// why.
    public var speed_info: [RestSchema.SpeedInfo]?
    /// Planned start date and time for this segment. Null when not set.
    public var start_at: Date?
    /// Turn-by-turn direction steps along the segment geometry, in travel order.
    /// Carried only by directions-mode segments; null for a linestring segment,
    /// which has no routed maneuvers. Also null on a directions segment whose
    /// geometry was never routed. Never an empty array.
    public var steps: [RestSchema.ItineraryDirectionsStep]?
    /// Surface type analysis segments along the segment geometry. Each entry
    /// references a coordinate index range. Null when the metric was never
    /// computed, and also null for a reader not entitled to the terrain analysis:
    /// a request made with a share token, and one made with a publishable key of
    /// an organization whose safety rules disable profile analysis. Never an
    /// empty array.
    public var surface_info: [RestSchema.SurfaceInfo]?
    /// Trail difficulty analysis segments along the segment geometry, graded on
    /// the SAC hiking scale for walking activities and the mountain-biking scale
    /// for cycling ones. Each entry references a coordinate index range. Null
    /// when the routing graph carries no trail-difficulty data or the metric was
    /// never computed, and also null for a reader not entitled to the terrain
    /// analysis: a request made with a share token, and one made with a
    /// publishable key of an organization whose safety rules disable profile
    /// analysis. Never an empty array.
    public var trail_difficulty_info: [RestSchema.TrailDifficultyInfo]?
    /// Way type analysis segments along the segment geometry. Each entry
    /// references a coordinate index range. Null when the metric was never
    /// computed, and also null for a reader not entitled to the terrain analysis:
    /// a request made with a share token, and one made with a publishable key of
    /// an organization whose safety rules disable profile analysis. Never an
    /// empty array.
    public var way_type_info: [RestSchema.WayTypeInfo]?

    /// Creates a `ItinerarySegment` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      altitude_max: Int?,
      altitude_min: Int?,
      ascent: Int?,
      color: String?,
      created_at: Date,
      created_by: RestSchema.RelationToUser,
      descent: Int?,
      description: String?,
      distance: Double?,
      duration: Double?,
      geojson: RestSchema.GeoJSONGeometry?,
      gradient_max: Double?,
      gradient_min: Double?,
      group_id: String?,
      id: String,
      itinerary_id: String,
      mode: RestSchema.SegmentMode,
      name: String,
      position: Int,
      revision: Int,
      road_access_info: [RestSchema.RoadAccessInfo]?,
      slope_info: [RestSchema.SlopeInfo]?,
      speed: Double?,
      speed_info: [RestSchema.SpeedInfo]?,
      start_at: Date?,
      steps: [RestSchema.ItineraryDirectionsStep]?,
      surface_info: [RestSchema.SurfaceInfo]?,
      trail_difficulty_info: [RestSchema.TrailDifficultyInfo]?,
      way_type_info: [RestSchema.WayTypeInfo]?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.altitude_max = altitude_max
      self.altitude_min = altitude_min
      self.ascent = ascent
      self.color = color
      self.created_at = created_at
      self.created_by = created_by
      self.descent = descent
      self.description = description
      self.distance = distance
      self.duration = duration
      self.geojson = geojson
      self.gradient_max = gradient_max
      self.gradient_min = gradient_min
      self.group_id = group_id
      self.id = id
      self.itinerary_id = itinerary_id
      self.mode = mode
      self.name = name
      self.position = position
      self.revision = revision
      self.road_access_info = road_access_info
      self.slope_info = slope_info
      self.speed = speed
      self.speed_info = speed_info
      self.start_at = start_at
      self.steps = steps
      self.surface_info = surface_info
      self.trail_difficulty_info = trail_difficulty_info
      self.way_type_info = way_type_info
      configure(&self)
    }

    /// Reads a `ItinerarySegment` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.altitude_max = try container.decodeIfPresent(Int.self, forKey: "altitude_max")
      self.altitude_min = try container.decodeIfPresent(Int.self, forKey: "altitude_min")
      self.ascent = try container.decodeIfPresent(Int.self, forKey: "ascent")
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.descent = try container.decodeIfPresent(Int.self, forKey: "descent")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.duration = try container.decodeIfPresent(Double.self, forKey: "duration")
      self.geojson = try container.decodeIfPresent(
        RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.gradient_max = try container.decodeIfPresent(Double.self, forKey: "gradient_max")
      self.gradient_min = try container.decodeIfPresent(Double.self, forKey: "gradient_min")
      self.group_id = try container.decodeIfPresent(String.self, forKey: "group_id")
      self.id = try container.decode(String.self, forKey: "id")
      self.itinerary_id = try container.decode(String.self, forKey: "itinerary_id")
      self.mode = try container.decode(RestSchema.SegmentMode.self, forKey: "mode")
      self.name = try container.decode(String.self, forKey: "name")
      self.position = try container.decode(Int.self, forKey: "position")
      self.revision = try container.decode(Int.self, forKey: "revision")
      self.road_access_info = try container.decodeIfPresent(
        [RestSchema.RoadAccessInfo].self, forKey: "road_access_info")
      self.slope_info = try container.decodeIfPresent(
        [RestSchema.SlopeInfo].self, forKey: "slope_info")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
      self.speed_info = try container.decodeIfPresent(
        [RestSchema.SpeedInfo].self, forKey: "speed_info")
      self.start_at = try container.decodeWiredIfPresent(Date.self, forKey: "start_at")
      self.steps = try container.decodeIfPresent(
        [RestSchema.ItineraryDirectionsStep].self, forKey: "steps")
      self.surface_info = try container.decodeIfPresent(
        [RestSchema.SurfaceInfo].self, forKey: "surface_info")
      self.trail_difficulty_info = try container.decodeIfPresent(
        [RestSchema.TrailDifficultyInfo].self, forKey: "trail_difficulty_info")
      self.way_type_info = try container.decodeIfPresent(
        [RestSchema.WayTypeInfo].self, forKey: "way_type_info")
    }

    /// Writes a `ItinerarySegment` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeNullable(self.altitude_max, forKey: "altitude_max")
      try container.encodeNullable(self.altitude_min, forKey: "altitude_min")
      try container.encodeNullable(self.ascent, forKey: "ascent")
      try container.encodeNullable(self.color, forKey: "color")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encodeNullable(self.descent, forKey: "descent")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encodeNullable(self.distance, forKey: "distance")
      try container.encodeNullable(self.duration, forKey: "duration")
      try container.encodeNullable(self.geojson, forKey: "geojson")
      try container.encodeNullable(self.gradient_max, forKey: "gradient_max")
      try container.encodeNullable(self.gradient_min, forKey: "gradient_min")
      try container.encodeNullable(self.group_id, forKey: "group_id")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.itinerary_id, forKey: "itinerary_id")
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.position, forKey: "position")
      try container.encode(self.revision, forKey: "revision")
      try container.encodeNullable(self.road_access_info, forKey: "road_access_info")
      try container.encodeNullable(self.slope_info, forKey: "slope_info")
      try container.encodeNullable(self.speed, forKey: "speed")
      try container.encodeNullable(self.speed_info, forKey: "speed_info")
      try container.encodeWiredNullable(self.start_at, forKey: "start_at")
      try container.encodeNullable(self.steps, forKey: "steps")
      try container.encodeNullable(self.surface_info, forKey: "surface_info")
      try container.encodeNullable(self.trail_difficulty_info, forKey: "trail_difficulty_info")
      try container.encodeNullable(self.way_type_info, forKey: "way_type_info")
    }
  }
}
