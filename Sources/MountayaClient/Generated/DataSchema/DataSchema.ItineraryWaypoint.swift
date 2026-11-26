// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// One waypoint of an itinerary: a single point along it.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ItineraryWaypoint: Sendable, Hashable, Codable {
    /// Waypoint identifier.
    public var id: String?
    /// Display name of the waypoint. Null only for a POINT, a standalone marker, which
    /// may be unnamed; a POI, a point of interest, always carries one.
    public var name: String?
    /// Free-text description of the waypoint. Null when it has none.
    public var description: String?
    /// Zero-based position of the waypoint within the itinerary's ordered chain.
    public var position: Int?
    /// Waypoint location as [longitude, latitude] (WGS 84); null when the waypoint has
    /// no geometry.
    public var point: [Double]?
    /// Services and facilities available at this waypoint, in no particular order and
    /// without duplicates. Empty when none are declared, never null, so it can be
    /// iterated unconditionally.
    public var amenities: [DataSchema.WaypointAmenity]?
    /// Cut-off and planned stop; null when the waypoint carries no timing.
    public var timing: DataSchema.WaypointTiming?
    /// How to reach the place this waypoint marks; null when the waypoint carries no contact
    /// detail.
    public var contact: DataSchema.WaypointContact?
    /// Photos and external links; null when none are attached, so a non-null value carries at least
    /// one of the two lists.
    public var media: DataSchema.WaypointMedia?
    /// Customer-defined fields, in the order they should be shown. Keys are unique
    /// within a waypoint. Null when the waypoint defines none. The empty case is
    /// carried as null rather than as an empty list, so check for null before
    /// iterating.
    public var properties: [DataSchema.WaypointProperty]?

    /// Creates a `ItineraryWaypoint` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.name = nil
      self.description = nil
      self.position = nil
      self.point = nil
      self.amenities = nil
      self.timing = nil
      self.contact = nil
      self.media = nil
      self.properties = nil
      configure(&self)
    }

    /// Reads a `ItineraryWaypoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.position = try container.decodeIfPresent(Int.self, forKey: "position")
      self.point = try container.decodeIfPresent([Double].self, forKey: "point")
      self.amenities = try container.decodeIfPresent(
        [DataSchema.WaypointAmenity].self, forKey: "amenities")
      self.timing = try container.decodeIfPresent(DataSchema.WaypointTiming.self, forKey: "timing")
      self.contact = try container.decodeIfPresent(
        DataSchema.WaypointContact.self, forKey: "contact")
      self.media = try container.decodeIfPresent(DataSchema.WaypointMedia.self, forKey: "media")
      self.properties = try container.decodeIfPresent(
        [DataSchema.WaypointProperty].self, forKey: "properties")
    }

    /// Writes a `ItineraryWaypoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.position, forKey: "position")
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.amenities, forKey: "amenities")
      try container.encodeIfPresent(self.timing, forKey: "timing")
      try container.encodeIfPresent(self.contact, forKey: "contact")
      try container.encodeIfPresent(self.media, forKey: "media")
      try container.encodeIfPresent(self.properties, forKey: "properties")
    }
  }
}
