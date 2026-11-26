// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for updating an existing segment. Only provided fields are updated.
  /// The geometry metrics (distance, duration, elevation, surface, and way type)
  /// are computed server-side from the geometry and are not accepted as inputs.
  ///
  /// The segment's mode is not settable here: changing which engine defines a
  /// segment re-derives its geometry and can fail routing, so it has its own
  /// operation (postItinerarySegmentConvert) with its own failure semantics.
  public struct SegmentUpdateParams: Sendable, Hashable, Codable {
    /// Hex color code for rendering this segment on the map. Both the three-digit
    /// and the six-digit forms are accepted, in either case, and either is stored
    /// as six lowercase digits (`#F60` and `#FF6600` both as `#ff6600`), which is
    /// the form every read returns. Omit to keep the current value; `null`
    /// returns the segment to the default activity color.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var color: String??
    /// Free-text description of the segment, at most 100 characters as sent,
    /// leading and trailing whitespace included; that whitespace is then
    /// trimmed. Omit to keep the current value; `null`, or a value that trims to
    /// nothing, clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var description: String??
    /// GeoJSON Geometry representing the segment path, read as the segment's
    /// mode reads it on creation. In directions mode it is a MultiPoint of 2 to
    /// 45 waypoints (inclusive), sent bare or inside a GeometryCollection whose
    /// MultiPoint alone is read, and the straight line through them must not
    /// exceed 100 km. In linestring mode it is a LineString, sent bare or inside
    /// a GeometryCollection, kept as drawn rather than routed and simplified and
    /// resampled as it is on creation. When that collection also holds a
    /// MultiPoint, the MultiPoint is read as the vertices drawn and the
    /// LineString only has to hold two positions, so a segment read with its
    /// drawn vertices changes path through its MultiPoint, or through a bare
    /// LineString sent in its place. Either way the segment's `geojson` as read
    /// is accepted back unchanged.
    ///
    /// The geometry holds at most 10,000 positions as sent. In linestring mode
    /// they are counted across every member of a collection. In directions
    /// mode only the MultiPoint read is counted: the routed LineString a
    /// directions segment is read with is not, whatever its length, so it is
    /// accepted back beside its MultiPoint, bounded only by the 32 MiB a JSON
    /// body may weigh. A linestring path measures at most 500 km. Either one
    /// past its ceiling is a 400 naming `geojson`.
    ///
    /// A position the segment's mode reads (in linestring mode every position
    /// of every member, in directions mode the MultiPoint's alone) outside the
    /// longitude and latitude ranges is a 400 naming it, and so is one of more
    /// than three numbers when every position carries the same count. The name
    /// runs through the member holding the position: `geojson.coordinates[0]`
    /// for the first position of a bare geometry,
    /// `geojson.geometries[1].coordinates[0]` for the first waypoint of a
    /// directions segment sent back as read. The routed LineString beside a
    /// directions MultiPoint is ignored, its positions included. Positions
    /// whose counts differ, and a position of fewer than two numbers, are
    /// refused in any member, that LineString included, as a 400 naming
    /// `geojson`.
    ///
    /// Optional and not nullable, unlike every other field on this operation:
    /// omit it to leave the stored geometry untouched. There is no way to clear a
    /// segment's geometry through this operation, because a segment without
    /// geometry cannot be routed or measured, so a `null` is a 400.
    public var geojson: RestSchema.GeoJSONGeometry?
    /// Display name of the segment. Omit to keep the current value. 2 to 30
    /// characters as sent; leading and trailing whitespace is then trimmed, and
    /// what remains must still be at least 2 characters. A name is one line: a
    /// tab, a line break or a line separator between two of its characters is a
    /// `400`, and one at either end is trimmed with the whitespace there.
    public var name: String?
    /// Travel speed in km/h used to compute the segment duration. Omit to keep
    /// the current value; `null` returns the segment to the default activity
    /// speed. At least 0.01 and at most 999.99, and stored rounded to two
    /// decimal places.
    ///
    /// A speed at which the segment would take longer than 99,999,999 seconds,
    /// a long freehand line drawn at a crawl, is a `400` naming `speed`.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var speed: Double??
    /// Planned start date and time for this segment. Omit to keep the current
    /// value; `null` clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var start_at: Date??

    /// Creates a `SegmentUpdateParams` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.color = nil
      self.description = nil
      self.geojson = nil
      self.name = nil
      self.speed = nil
      self.start_at = nil
      configure(&self)
    }

    /// Reads a `SegmentUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.color = try container.decodeMerge(String.self, forKey: "color")
      self.description = try container.decodeMerge(String.self, forKey: "description")
      self.geojson = try container.decodeIfPresent(
        RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.speed = try container.decodeMerge(Double.self, forKey: "speed")
      self.start_at = try container.decodeWiredMerge(Date.self, forKey: "start_at")
    }

    /// Writes a `SegmentUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.color, forKey: "color")
      try container.encodeMerge(self.description, forKey: "description")
      try container.encodeIfPresent(self.geojson, forKey: "geojson")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeMerge(self.speed, forKey: "speed")
      try container.encodeWiredMerge(self.start_at, forKey: "start_at")
    }
  }
}
