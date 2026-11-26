// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One finalized waypoint of a confirmed itinerary import. `mode` and `geojson`
  /// are always required, and a `poi` requires `name` and `icon` as well; a
  /// `point` may carry neither.
  public struct ItineraryImportConfirmWaypoint: Sendable, Hashable, Codable {
    /// Whether the waypoint is a point of interest, which carries a name and an
    /// icon, or a standalone point marker, which may be unnamed.
    public var mode: RestSchema.WaypointMode
    /// A bare GeoJSON Point representing the waypoint location, the shape a
    /// preview proposes it in. Any other geometry, a GeometryCollection holding
    /// a Point included, is a 400 naming that waypoint's `geojson`. A position
    /// outside the longitude and latitude ranges, or one of more than three
    /// numbers, is a 400 naming the position at fault, for example
    /// `geojson[0]`.
    public var geojson: RestSchema.GeoJSONGeometry
    /// Display name of the waypoint, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. Required when `mode` is `poi`; a `point` may omit it.
    /// A `poi` sent without one is a `400` naming `name`. A name is one line: a
    /// tab, a line break or a line separator between two of its characters is a
    /// `400`, and one at either end is trimmed with the whitespace there.
    public var name: String?
    /// Free-text description of the waypoint, at most 100 characters as sent,
    /// leading and trailing whitespace included; that whitespace is then
    /// trimmed. Omit it, or send one that trims to nothing, to create the
    /// waypoint without one.
    public var description: String?
    /// Icon to draw this waypoint with. Required for a `poi`, which sent without
    /// one is a `400` naming `icon`; optional for a `point`, which shows it when
    /// set. `flag-start` and `flag-end` are refused on every write (400). Not
    /// nullable: omit it for a `point` without one.
    public var icon: RestSchema.WaypointIcon?

    /// Creates a `ItineraryImportConfirmWaypoint` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      mode: RestSchema.WaypointMode,
      geojson: RestSchema.GeoJSONGeometry,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.mode = mode
      self.geojson = geojson
      self.name = nil
      self.description = nil
      self.icon = nil
      configure(&self)
    }

    /// Reads a `ItineraryImportConfirmWaypoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.mode = try container.decode(RestSchema.WaypointMode.self, forKey: "mode")
      self.geojson = try container.decode(RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.icon = try container.decodeIfPresent(RestSchema.WaypointIcon.self, forKey: "icon")
    }

    /// Writes a `ItineraryImportConfirmWaypoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.geojson, forKey: "geojson")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.icon, forKey: "icon")
    }
  }
}
