// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One finalized segment of a confirmed itinerary import: the user-reviewed mode,
  /// defining geometry (waypoint MultiPoint for directions, line for linestring),
  /// name, and optional color. Metrics are recomputed server-side from the geometry
  /// at confirm time and are never accepted as inputs.
  public struct ItineraryImportConfirmSegment: Sendable, Hashable, Codable {
    /// How the segment's path is defined, which decides what `geojson` must
    /// carry: `directions` routes between the waypoints of a MultiPoint,
    /// `linestring` keeps the drawn line rather than routing it.
    public var mode: RestSchema.SegmentMode
    /// GeoJSON Geometry defining the segment, as `mode` reads it. For
    /// `directions` it is a MultiPoint of 2 to 45 waypoints the route passes
    /// through in order, and the straight line through them must not exceed
    /// 100 km; what is stored is the route computed again at confirm. For
    /// `linestring` it is the LineString drawn, kept as drawn rather than
    /// routed: the server simplifies it to a 3 m tolerance to remove GPS
    /// jitter, resamples it to about one point every 50 m carrying each point's
    /// elevation, and, when that adds points and the vertices drawn number
    /// fewer than the line's sample budget `ItinerarySegment.geojson` states,
    /// stores those vertices beside it as a MultiPoint in a GeometryCollection.
    /// Any other line, a dense recorded track among them, is stored as the bare
    /// resampled LineString. The candidate geometry a
    /// preview proposed, GeometryCollection included, can be sent back
    /// unchanged.
    ///
    /// Every segment after the first has its first position replaced with the
    /// last point computed for the segment before it, so the chain is stored
    /// connected whatever gap the reviewed draft held.
    ///
    /// The geometry holds at most 10,000 positions as sent. In `linestring`
    /// mode they are counted across every member of a collection. In
    /// `directions` mode only the MultiPoint read is counted: a LineString
    /// beside it, the routed line of the candidate a preview proposed
    /// included, is not, whatever its length, and only the 32 MiB a JSON body
    /// may weigh bounds it. A `linestring` path measures at most 500 km.
    /// Either one past its ceiling is a 400 naming that segment's `geojson`,
    /// `segments[2].geojson` for the third, before any segment is routed, and
    /// nothing is created.
    ///
    /// A position the segment's mode reads (every position of a `linestring`
    /// segment, the MultiPoint's of a `directions` one) outside the longitude
    /// and latitude ranges, or one of more than three numbers, is a 400 naming
    /// the position at fault, for example `segments[0].geojson.coordinates[0]`
    /// for the first position of the first segment sent bare. A draft names at
    /// most 10,000 such faults across its segments, the first in draft order:
    /// a segment reached after them is still held to the position ceiling, and
    /// the rest of its geometry is checked once those faults are fixed.
    /// Waypoints the routing engine cannot route between, in a `directions`
    /// segment, are a 400 naming that segment's `geojson`, `segments[1].geojson`
    /// for the second, and nothing is created.
    public var geojson: RestSchema.GeoJSONGeometry
    /// Display name of the segment, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var name: String
    /// Hex color code for rendering this segment on the map. Both the three-digit
    /// and the six-digit forms are accepted, in either case, and either is stored
    /// as six lowercase digits (`#F60` and `#FF6600` both as `#ff6600`), which is
    /// the form every read returns.
    ///
    /// Optional and not nullable: omit it to use the default activity color.
    public var color: String?
    /// Travel speed in km/h used to compute the segment duration. At least 0.01
    /// and at most 999.99, and stored rounded to two decimal places.
    ///
    /// Optional and not nullable: omit it to use the default activity speed.
    ///
    /// A speed at which the segment would take longer than 99,999,999 seconds,
    /// a long freehand line drawn at a crawl, is a `400` naming `speed`.
    public var speed: Double?

    /// Creates a `ItineraryImportConfirmSegment` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      mode: RestSchema.SegmentMode,
      geojson: RestSchema.GeoJSONGeometry,
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.mode = mode
      self.geojson = geojson
      self.name = name
      self.color = nil
      self.speed = nil
      configure(&self)
    }

    /// Reads a `ItineraryImportConfirmSegment` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.mode = try container.decode(RestSchema.SegmentMode.self, forKey: "mode")
      self.geojson = try container.decode(RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.name = try container.decode(String.self, forKey: "name")
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
    }

    /// Writes a `ItineraryImportConfirmSegment` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.geojson, forKey: "geojson")
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.color, forKey: "color")
      try container.encodeIfPresent(self.speed, forKey: "speed")
    }
  }
}
