// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for creating a new waypoint within an itinerary. `mode`,
  /// `position` and `geojson` are always required, and a `poi` requires `name`
  /// and `icon` as well; a `point` may carry neither.
  ///
  /// Every optional field is optional and not nullable: omitting it is how a
  /// caller says there is none, so an explicit `null` is refused rather than read
  /// as a second way of saying the same thing. The update operation is where
  /// `null` clears a stored value. Inside `contact`, `media`, `timing` and each
  /// entry of `properties`, a member may be `null`, which reads as absent.
  public struct WaypointCreateParams: Sendable, Hashable, Codable {
    /// Services and facilities available at this waypoint. Duplicates are
    /// rejected. Optional and not nullable: omit it for none.
    public var amenities: [RestSchema.WaypointAmenity]?
    /// Hex color code for rendering this waypoint on the map. Both the
    /// three-digit and the six-digit forms are accepted, in either case, and
    /// either is stored as six lowercase digits (`#F60` and `#FF6600` both as
    /// `#ff6600`), which is the form every read returns.
    ///
    /// Optional and not nullable: omit it to use the default activity color.
    public var color: String?
    /// How to reach the place this waypoint marks. An object whose members are
    /// all null or absent is stored as none, and reads back as `null`.
    ///
    /// Optional and not nullable: omit it for none.
    public var contact: RestSchema.WaypointContact?
    /// Free-text description of the waypoint, at most 100 characters as sent,
    /// leading and trailing whitespace included; that whitespace is then
    /// trimmed. Omit it, or send one that trims to nothing, to create the
    /// waypoint without one.
    public var description: String?
    /// A bare GeoJSON Point representing the waypoint location, the shape a
    /// waypoint's `geojson` is read in. Any other geometry, a
    /// GeometryCollection holding a Point included, is a 400 naming `geojson`.
    /// Both modes require it, so omitting it is a 400. A position outside the
    /// longitude and latitude ranges, or one of more than three numbers, is a 400
    /// naming the position at fault, for example `geojson[0]`.
    public var geojson: RestSchema.GeoJSONGeometry
    /// Icon displayed on the waypoint. Required for a `poi`, which sent without
    /// one is a `400` naming `icon`; optional for a `point`, which shows it when
    /// set. `flag-start` and `flag-end` are refused on every write (400). Not
    /// nullable: omit it for a `point` without one.
    public var icon: RestSchema.WaypointIcon?
    /// Photos and external links attached to this waypoint. An object whose
    /// members are all null, absent or empty lists is stored as none, and reads
    /// back as `null`.
    ///
    /// Optional and not nullable: omit it for none.
    public var media: RestSchema.WaypointMedia?
    /// Whether the waypoint is a point of interest, which carries a name and an
    /// icon, or a standalone point marker, which may be unnamed.
    public var mode: RestSchema.WaypointMode
    /// Display name of the waypoint, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. Required when `mode` is `poi`; a `point` may omit it.
    /// A `poi` sent without one is a `400` naming `name`. A name is one line: a
    /// tab, a line break or a line separator between two of its characters is a
    /// `400`, and one at either end is trimmed with the whitespace there.
    public var name: String?
    /// Zero-based position of the waypoint within its parent itinerary, stored as
    /// given: a waypoint's order is the author's choice, and no other waypoint
    /// moves to make room. Between 0 and 9999.
    public var position: Int
    /// Customer-defined fields for this waypoint, in the order they should be
    /// shown. Keys must be unique within the waypoint. At most 20: the server
    /// enforces the ceiling, and a list over it is a validation error rather than
    /// a truncation.
    ///
    /// Optional and not nullable: omit it for none.
    public var properties: [RestSchema.WaypointProperty]?
    /// Cut-off and expected-arrival timing for this waypoint. An object whose
    /// members are all null or absent is stored as none, and reads back as
    /// `null`.
    ///
    /// Optional and not nullable: omit it for none.
    public var timing: RestSchema.WaypointTiming?

    /// Creates a `WaypointCreateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      geojson: RestSchema.GeoJSONGeometry,
      mode: RestSchema.WaypointMode,
      position: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.amenities = nil
      self.color = nil
      self.contact = nil
      self.description = nil
      self.geojson = geojson
      self.icon = nil
      self.media = nil
      self.mode = mode
      self.name = nil
      self.position = position
      self.properties = nil
      self.timing = nil
      configure(&self)
    }

    /// Reads a `WaypointCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.amenities = try container.decodeIfPresent(
        [RestSchema.WaypointAmenity].self, forKey: "amenities")
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
      self.contact = try container.decodeIfPresent(
        RestSchema.WaypointContact.self, forKey: "contact")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.geojson = try container.decode(RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.icon = try container.decodeIfPresent(RestSchema.WaypointIcon.self, forKey: "icon")
      self.media = try container.decodeIfPresent(RestSchema.WaypointMedia.self, forKey: "media")
      self.mode = try container.decode(RestSchema.WaypointMode.self, forKey: "mode")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.position = try container.decode(Int.self, forKey: "position")
      self.properties = try container.decodeIfPresent(
        [RestSchema.WaypointProperty].self, forKey: "properties")
      self.timing = try container.decodeIfPresent(RestSchema.WaypointTiming.self, forKey: "timing")
    }

    /// Writes a `WaypointCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.amenities, forKey: "amenities")
      try container.encodeIfPresent(self.color, forKey: "color")
      try container.encodeIfPresent(self.contact, forKey: "contact")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encode(self.geojson, forKey: "geojson")
      try container.encodeIfPresent(self.icon, forKey: "icon")
      try container.encodeIfPresent(self.media, forKey: "media")
      try container.encode(self.mode, forKey: "mode")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encode(self.position, forKey: "position")
      try container.encodeIfPresent(self.properties, forKey: "properties")
      try container.encodeIfPresent(self.timing, forKey: "timing")
    }
  }
}
