// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for creating a new segment within an itinerary: appended to the
  /// end of its chain, or inserted before the segment `before_segment_id` names.
  /// The geometry metrics (distance, duration, elevation, surface, and way type)
  /// are computed from the geometry and are not accepted as inputs.
  public struct SegmentCreateParams: Sendable, Hashable, Codable {
    /// Identifier of the segment the new one is inserted BEFORE, so the first
    /// segment's identifier inserts at the head of the chain. Optional and not
    /// nullable: omit it to append the new segment to the end of the chain.
    ///
    /// An identifier that names no segment of this itinerary's chain, one of
    /// another itinerary or one already deleted included, is a 400 naming
    /// `before_segment_id` rather than a 404.
    public var before_segment_id: String?
    /// Hex color code for rendering this segment on the map. Both the three-digit
    /// and the six-digit forms are accepted, in either case, and either is stored
    /// as six lowercase digits (`#F60` and `#FF6600` both as `#ff6600`), which is
    /// the form every read returns.
    ///
    /// Optional and not nullable: omit it to use the default activity color. The
    /// update operation types the same field nullable, because there `null`
    /// returns a segment to that default.
    public var color: String?
    /// Free-text description of the segment, at most 100 characters as sent,
    /// leading and trailing whitespace included; that whitespace is then
    /// trimmed. Omit it, or send one that trims to nothing, to create the segment
    /// without one.
    public var description: String?
    /// The segment's path, as `mode` reads it. In `directions` mode it is a
    /// MultiPoint of 2 to 45 waypoints the route passes through in order, and
    /// the straight line through them must not exceed 100 km; what is stored is
    /// the route computed between them. The MultiPoint is sent bare or inside a
    /// GeometryCollection, the shape a `directions` segment is read in, and only
    /// the collection's MultiPoint is read: a LineString beside it is ignored.
    ///
    /// In `linestring` mode it is the LineString drawn, kept as drawn rather
    /// than routed: the server simplifies it to a 3 m tolerance to remove GPS
    /// jitter, resamples it to about one point every 50 m carrying each point's
    /// elevation, and, when that adds points and the vertices drawn number
    /// fewer than the line's sample budget `ItinerarySegment.geojson` states,
    /// stores those vertices beside it as a MultiPoint in a GeometryCollection.
    /// Any other line, a dense recorded track among them, is stored as the bare
    /// resampled LineString. The LineString is sent bare
    /// or inside a GeometryCollection. When that collection also holds a
    /// MultiPoint, the MultiPoint is read as the vertices drawn: the path is
    /// measured, resampled and analysed from it, and the LineString only has to
    /// hold two positions. A `linestring` segment read with its drawn vertices
    /// therefore changes path through its MultiPoint, or through a bare
    /// LineString sent in its place, never through the LineString beside it.
    ///
    /// Appended to an itinerary that already has segments, the first position
    /// is replaced with the last point of the current last segment, so the new
    /// segment starts where the chain ends, and the 100 km limit is checked
    /// after that replacement. Inserted with `before_segment_id`, the ends are
    /// kept where they were sent: the neighbouring segments move to meet this
    /// one. A `directions` segment is pinned onto every junction it shares with
    /// a neighbour, a short straight connector joining the route to one off the
    /// routable network, so it stays exactly connected to the chain.
    ///
    /// The geometry holds at most 10,000 positions as sent. In `linestring`
    /// mode they are counted across every member of a collection. In
    /// `directions` mode only the MultiPoint read is counted: a LineString
    /// beside it, the routed line a `directions` segment is read with
    /// included, is not, whatever its length, and only the 32 MiB a JSON body
    /// may weigh bounds it. A `linestring` path measures at most 500 km. Either
    /// one past its ceiling is a 400 naming `geojson`.
    ///
    /// Every position is `[longitude, latitude]`, with an optional altitude in
    /// meters. A position `mode` reads (in `linestring` mode every position of
    /// every member, in `directions` mode the MultiPoint's alone) outside the
    /// longitude and latitude ranges is a 400 naming it, and so is one of more
    /// than three numbers when every position carries the same count. The name
    /// runs through the member holding the position: `geojson.coordinates[0]`
    /// for the first position of a bare geometry,
    /// `geojson.geometries[1].coordinates[0]` for the first waypoint of a
    /// `directions` segment sent back as read. A LineString beside a
    /// `directions` MultiPoint is ignored, its positions included. Positions
    /// whose counts differ, and a position of fewer than two numbers, are
    /// refused in any member, that LineString included, as a 400 naming
    /// `geojson`.
    public var geojson: RestSchema.GeoJSONGeometry
    /// How the segment's path is defined, which decides what `geojson` must
    /// carry: `directions` routes between the waypoints of a MultiPoint,
    /// `linestring` keeps the drawn line rather than routing it.
    public var mode: RestSchema.SegmentMode
    /// Display name of the segment, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var name: String
    /// Travel speed in km/h used to compute the segment duration. At least 0.01
    /// and at most 999.99, and stored rounded to two decimal places.
    ///
    /// Optional and not nullable: omit it to use the default activity speed. The
    /// update operation types the same field nullable, because there `null`
    /// returns a segment to that default.
    ///
    /// A speed at which the segment would take longer than 99,999,999 seconds,
    /// a long freehand line drawn at a crawl, is a `400` naming `speed`.
    public var speed: Double?
    /// Planned start date and time for this segment.
    ///
    /// Optional and not nullable: omit it to create the segment without one. The
    /// update operation types the same field nullable, because there `null`
    /// clears it.
    public var start_at: Date?

    /// Creates a `SegmentCreateParams` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      geojson: RestSchema.GeoJSONGeometry,
      mode: RestSchema.SegmentMode,
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.before_segment_id = nil
      self.color = nil
      self.description = nil
      self.geojson = geojson
      self.mode = mode
      self.name = name
      self.speed = nil
      self.start_at = nil
      configure(&self)
    }

    /// Reads a `SegmentCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.before_segment_id = try container.decodeIfPresent(
        String.self, forKey: "before_segment_id")
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.geojson = try container.decode(RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.mode = try container.decode(RestSchema.SegmentMode.self, forKey: "mode")
      self.name = try container.decode(String.self, forKey: "name")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
      self.start_at = try container.decodeWiredIfPresent(Date.self, forKey: "start_at")
    }

    /// Writes a `SegmentCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.before_segment_id, forKey: "before_segment_id")
      try container.encodeIfPresent(self.color, forKey: "color")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encode(self.geojson, forKey: "geojson")
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.speed, forKey: "speed")
      try container.encodeWiredIfPresent(self.start_at, forKey: "start_at")
    }
  }
}
