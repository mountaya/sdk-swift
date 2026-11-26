// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A standalone waypoint on an itinerary: a point of interest or a point marker
  /// with an optional name, icon, color, and a Point location.
  ///
  /// Beyond that marker, a waypoint describes the place it sits on: what is
  /// available there (`amenities`), when it opens and closes (`timing`), how to
  /// reach it (`contact`), what it looks like (`media`), and whatever else the
  /// author needs to publish about it (`properties`).
  ///
  /// Altitude and distance along the route are deliberately absent. Both are
  /// derived from the itinerary's geometry when the waypoint is projected onto it,
  /// and storing them here would create a second answer that drifts from the first.
  public struct ItineraryWaypoint: Sendable, Hashable, Codable {
    /// Services and facilities available at this waypoint, in no particular order
    /// and without duplicates. Empty when none are declared, never null, so a
    /// reader can iterate it unconditionally.
    public var amenities: [RestSchema.WaypointAmenity]
    /// Hex color code for rendering this waypoint on the map. Always the
    /// six-digit lowercase form, whichever form was written. Null when using the
    /// default activity color.
    public var color: String?
    /// How to reach the place this waypoint marks. Null when no contact details
    /// are provided, including when every member of the object written was null
    /// or absent.
    public var contact: RestSchema.WaypointContact?
    /// Timestamp of the waypoint's creation.
    public var created_at: Date
    /// The user who created the waypoint. It is the author rather than the last
    /// editor, and it does not move when another member edits the waypoint.
    public var created_by: RestSchema.RelationToUser
    /// Free-text description of the waypoint. Null when it has none.
    public var description: String?
    /// The waypoint's location, a bare GeoJSON Point, never a collection holding
    /// one: the shape every waypoint write takes, so a location read can be sent
    /// back as it is. Null when the waypoint has no location yet.
    public var geojson: RestSchema.GeoJSONGeometry?
    /// Icon for the waypoint. A `poi` always carries one; a `point` carries one
    /// when it was given one. Null when not provided.
    public var icon: RestSchema.WaypointIcon?
    /// Unique identifier of the waypoint.
    public var id: String
    /// Identifier of the parent itinerary.
    public var itinerary_id: String
    /// Photos and external links attached to this waypoint. Null when none are
    /// attached, including when every member of the object written was null,
    /// absent or an empty list.
    public var media: RestSchema.WaypointMedia?
    /// Whether the waypoint is a point of interest, which carries a name and an
    /// icon, or a standalone point marker, which may be unnamed.
    public var mode: RestSchema.WaypointMode
    /// Display name of the waypoint. Null only for a `point`, which may be
    /// unnamed; a `poi` always carries one.
    public var name: String?
    /// Zero-based position of the waypoint within its parent itinerary. Set by
    /// the caller, unlike a segment's: a waypoint is a standalone marker whose
    /// order is the author's choice, where a segment's position is derived from
    /// the chain it sits in and is `readOnly` for that reason. Creating a
    /// waypoint requires one and an update may move it.
    public var position: Int
    /// Customer-defined fields for this waypoint, in the order they should be
    /// shown. Keys are unique within a waypoint. Null when none are defined.
    /// Never an empty array. At most 20: the server enforces the ceiling, and a
    /// list over it is a validation error rather than a truncation.
    public var properties: [RestSchema.WaypointProperty]?
    /// Revision number of the waypoint, incremented on each change. A consumer
    /// holding an older copy compares it with the `revision` a change frame
    /// carries; no request takes it.
    public var revision: Int
    /// Cut-off and expected-arrival timing published for this waypoint. Null when
    /// the waypoint carries no timing, including when every member of the object
    /// written was null or absent.
    public var timing: RestSchema.WaypointTiming?

    /// Creates a `ItineraryWaypoint` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      amenities: [RestSchema.WaypointAmenity],
      color: String?,
      contact: RestSchema.WaypointContact?,
      created_at: Date,
      created_by: RestSchema.RelationToUser,
      description: String?,
      geojson: RestSchema.GeoJSONGeometry?,
      icon: RestSchema.WaypointIcon?,
      id: String,
      itinerary_id: String,
      media: RestSchema.WaypointMedia?,
      mode: RestSchema.WaypointMode,
      name: String?,
      position: Int,
      properties: [RestSchema.WaypointProperty]?,
      revision: Int,
      timing: RestSchema.WaypointTiming?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.amenities = amenities
      self.color = color
      self.contact = contact
      self.created_at = created_at
      self.created_by = created_by
      self.description = description
      self.geojson = geojson
      self.icon = icon
      self.id = id
      self.itinerary_id = itinerary_id
      self.media = media
      self.mode = mode
      self.name = name
      self.position = position
      self.properties = properties
      self.revision = revision
      self.timing = timing
      configure(&self)
    }

    /// Reads a `ItineraryWaypoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.amenities = try container.decode([RestSchema.WaypointAmenity].self, forKey: "amenities")
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
      self.contact = try container.decodeIfPresent(
        RestSchema.WaypointContact.self, forKey: "contact")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.geojson = try container.decodeIfPresent(
        RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.icon = try container.decodeIfPresent(RestSchema.WaypointIcon.self, forKey: "icon")
      self.id = try container.decode(String.self, forKey: "id")
      self.itinerary_id = try container.decode(String.self, forKey: "itinerary_id")
      self.media = try container.decodeIfPresent(RestSchema.WaypointMedia.self, forKey: "media")
      self.mode = try container.decode(RestSchema.WaypointMode.self, forKey: "mode")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.position = try container.decode(Int.self, forKey: "position")
      self.properties = try container.decodeIfPresent(
        [RestSchema.WaypointProperty].self, forKey: "properties")
      self.revision = try container.decode(Int.self, forKey: "revision")
      self.timing = try container.decodeIfPresent(RestSchema.WaypointTiming.self, forKey: "timing")
    }

    /// Writes a `ItineraryWaypoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.amenities, forKey: "amenities")
      try container.encodeNullable(self.color, forKey: "color")
      try container.encodeNullable(self.contact, forKey: "contact")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encodeNullable(self.geojson, forKey: "geojson")
      try container.encodeNullable(self.icon, forKey: "icon")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.itinerary_id, forKey: "itinerary_id")
      try container.encodeNullable(self.media, forKey: "media")
      try container.encode(self.mode, forKey: "mode")
      try container.encodeNullable(self.name, forKey: "name")
      try container.encode(self.position, forKey: "position")
      try container.encodeNullable(self.properties, forKey: "properties")
      try container.encode(self.revision, forKey: "revision")
      try container.encodeNullable(self.timing, forKey: "timing")
    }
  }
}
