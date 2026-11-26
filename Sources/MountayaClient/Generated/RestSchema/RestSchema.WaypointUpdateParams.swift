// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for updating an existing waypoint. Only provided fields are
  /// updated.
  public struct WaypointUpdateParams: Sendable, Hashable, Codable {
    /// Services and facilities available at this waypoint. Replaces the stored
    /// list wholesale rather than merging into it. Duplicates are rejected. Omit
    /// it to keep the current list; `null` or an empty array clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var amenities: [RestSchema.WaypointAmenity]??
    /// Hex color code for rendering this waypoint on the map. Both the
    /// three-digit and the six-digit forms are accepted, in either case, and
    /// either is stored as six lowercase digits (`#F60` and `#FF6600` both as
    /// `#ff6600`), which is the form every read returns. Omit it to keep the
    /// current value; `null` returns the waypoint to the default activity color.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var color: String??
    /// How to reach the place this waypoint marks. Replaces the stored object
    /// wholesale rather than merging into it. Omit it to keep the current value;
    /// `null`, or an object whose members are all null or absent, clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var contact: RestSchema.WaypointContact??
    /// Free-text description of the waypoint, at most 100 characters as sent,
    /// leading and trailing whitespace included; that whitespace is then
    /// trimmed. Omit to keep the current value; `null`, or a value that trims to
    /// nothing, clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var description: String??
    /// A bare GeoJSON Point representing the waypoint location, the shape a
    /// waypoint's `geojson` is read in, so a location read can be sent back as
    /// it is. Any other geometry, a GeometryCollection holding a Point
    /// included, is a 400 naming `geojson`. Optional and not nullable: omit it
    /// to leave the stored location untouched; a `null` is a 400. A position
    /// outside the longitude and latitude ranges, or one of more than three
    /// numbers, is a 400 naming the position at fault, for example
    /// `geojson[0]`.
    public var geojson: RestSchema.GeoJSONGeometry?
    /// Icon displayed on the waypoint. Required for a `poi`; optional for a
    /// `point`, which shows it when set. `flag-start` and `flag-end` are refused
    /// on every write (400). Optional and not nullable: omit it to leave the
    /// stored icon untouched. Unlike `name`, `description` and `color`, which are
    /// nullable here, an icon cannot be cleared through this operation.
    public var icon: RestSchema.WaypointIcon?
    /// Photos and external links attached to this waypoint. Replaces the stored
    /// object wholesale rather than merging into it. Omit it to keep the current
    /// value; `null`, or an object whose members are all null, absent or empty
    /// lists, clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var media: RestSchema.WaypointMedia??
    /// Display name of the waypoint, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. Omit to keep the current value; `null` clears it. A
    /// `poi` requires a name, so clearing a `poi`'s name is a `400` naming
    /// `name`; a `point` may be unnamed. A name is one line: a tab, a line break
    /// or a line separator between two of its characters is a `400`, and one at
    /// either end is trimmed with the whitespace there.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var name: String??
    /// Zero-based position of the waypoint within its parent itinerary, stored as
    /// given: no other waypoint moves to make room. Optional and not nullable:
    /// omit it to keep the current position. Between 0 and 9999.
    public var position: Int?
    /// Customer-defined fields for this waypoint. Replaces the stored list
    /// wholesale rather than merging into it. Keys must be unique within the
    /// waypoint. Omit it to keep the current list; `null` or an empty array
    /// clears it. At most 20: the server
    /// enforces the ceiling, and a list over it is a validation error rather than
    /// a truncation.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var properties: [RestSchema.WaypointProperty]??
    /// Cut-off and expected-arrival timing for this waypoint. Replaces the stored
    /// object wholesale rather than merging into it. Omit it to keep the current
    /// value; `null`, or an object whose members are all null or absent, clears
    /// it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var timing: RestSchema.WaypointTiming??

    /// Creates a `WaypointUpdateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.amenities = nil
      self.color = nil
      self.contact = nil
      self.description = nil
      self.geojson = nil
      self.icon = nil
      self.media = nil
      self.name = nil
      self.position = nil
      self.properties = nil
      self.timing = nil
      configure(&self)
    }

    /// Reads a `WaypointUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.amenities = try container.decodeMerge(
        [RestSchema.WaypointAmenity].self, forKey: "amenities")
      self.color = try container.decodeMerge(String.self, forKey: "color")
      self.contact = try container.decodeMerge(RestSchema.WaypointContact.self, forKey: "contact")
      self.description = try container.decodeMerge(String.self, forKey: "description")
      self.geojson = try container.decodeIfPresent(
        RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.icon = try container.decodeIfPresent(RestSchema.WaypointIcon.self, forKey: "icon")
      self.media = try container.decodeMerge(RestSchema.WaypointMedia.self, forKey: "media")
      self.name = try container.decodeMerge(String.self, forKey: "name")
      self.position = try container.decodeIfPresent(Int.self, forKey: "position")
      self.properties = try container.decodeMerge(
        [RestSchema.WaypointProperty].self, forKey: "properties")
      self.timing = try container.decodeMerge(RestSchema.WaypointTiming.self, forKey: "timing")
    }

    /// Writes a `WaypointUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.amenities, forKey: "amenities")
      try container.encodeMerge(self.color, forKey: "color")
      try container.encodeMerge(self.contact, forKey: "contact")
      try container.encodeMerge(self.description, forKey: "description")
      try container.encodeIfPresent(self.geojson, forKey: "geojson")
      try container.encodeIfPresent(self.icon, forKey: "icon")
      try container.encodeMerge(self.media, forKey: "media")
      try container.encodeMerge(self.name, forKey: "name")
      try container.encodeIfPresent(self.position, forKey: "position")
      try container.encodeMerge(self.properties, forKey: "properties")
      try container.encodeMerge(self.timing, forKey: "timing")
    }
  }
}
