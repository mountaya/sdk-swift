// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A single itinerary with its segments and waypoints.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct ItineraryResult: Sendable, Hashable, Codable {
    /// Itinerary identifier.
    public var id: String?
    /// Display name of the itinerary.
    public var name: String?
    /// Free-text description of the itinerary. Null when it has none.
    public var description: String?
    /// Itinerary activity slug; null when no activity is assigned.
    public var activitySlug: DataSchema.ActivitySlug?
    /// Total distance across all of the itinerary's segments, in meters; null when no
    /// segment contributes a distance value (for example the itinerary has no segments,
    /// or none have been computed).
    public var distance: Double?
    /// Total elevation gain across all of the itinerary's segments, in meters; null when
    /// no segment contributes an ascent value.
    public var ascent: Int?
    /// Whether the itinerary is private. A private itinerary is served only to a key
    /// of the organization that owns it; no other organization's key reaches it, even
    /// with its id. A public one ('anyone with the link') is also served by id to any
    /// other organization's key, as last published, but is never listed in another
    /// organization's search results.
    public var isPrivate: Bool?
    /// Identifier of the organization that owns this itinerary. Null for a personal
    /// itinerary, made from an individual account and owned by no organization.
    public var organizationId: String?
    /// Segments in itinerary order.
    public var segments: [DataSchema.ItinerarySegment]?
    /// Waypoints in itinerary order.
    public var waypoints: [DataSchema.ItineraryWaypoint]?
    /// Segment groups defined on this itinerary, in no guaranteed order: key them by
    /// `id` rather than by position. Flat rather than nested inside the segments: the
    /// ordered segment chain stays the itinerary's primary structure, and each segment
    /// points back at its group through `groupId`. Empty when the itinerary has no
    /// groups.
    public var groups: [DataSchema.ItinerarySegmentGroup]?
    /// Number of segments on the itinerary. Always equals the length of `segments`.
    public var segmentCount: Int?
    /// Number of waypoints on the itinerary. Always equals the length of `waypoints`.
    public var waypointCount: Int?
    /// Number of segment groups on the itinerary. Always equals the length of `groups`.
    public var groupCount: Int?

    /// Creates a `ItineraryResult` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.name = nil
      self.description = nil
      self.activitySlug = nil
      self.distance = nil
      self.ascent = nil
      self.isPrivate = nil
      self.organizationId = nil
      self.segments = nil
      self.waypoints = nil
      self.groups = nil
      self.segmentCount = nil
      self.waypointCount = nil
      self.groupCount = nil
      configure(&self)
    }

    /// Reads a `ItineraryResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.activitySlug = try container.decodeIfPresent(
        DataSchema.ActivitySlug.self, forKey: "activitySlug")
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.ascent = try container.decodeIfPresent(Int.self, forKey: "ascent")
      self.isPrivate = try container.decodeIfPresent(Bool.self, forKey: "isPrivate")
      self.organizationId = try container.decodeIfPresent(String.self, forKey: "organizationId")
      self.segments = try container.decodeIfPresent(
        [DataSchema.ItinerarySegment].self, forKey: "segments")
      self.waypoints = try container.decodeIfPresent(
        [DataSchema.ItineraryWaypoint].self, forKey: "waypoints")
      self.groups = try container.decodeIfPresent(
        [DataSchema.ItinerarySegmentGroup].self, forKey: "groups")
      self.segmentCount = try container.decodeIfPresent(Int.self, forKey: "segmentCount")
      self.waypointCount = try container.decodeIfPresent(Int.self, forKey: "waypointCount")
      self.groupCount = try container.decodeIfPresent(Int.self, forKey: "groupCount")
    }

    /// Writes a `ItineraryResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.activitySlug, forKey: "activitySlug")
      try container.encodeIfPresent(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.ascent, forKey: "ascent")
      try container.encodeIfPresent(self.isPrivate, forKey: "isPrivate")
      try container.encodeIfPresent(self.organizationId, forKey: "organizationId")
      try container.encodeIfPresent(self.segments, forKey: "segments")
      try container.encodeIfPresent(self.waypoints, forKey: "waypoints")
      try container.encodeIfPresent(self.groups, forKey: "groups")
      try container.encodeIfPresent(self.segmentCount, forKey: "segmentCount")
      try container.encodeIfPresent(self.waypointCount, forKey: "waypointCount")
      try container.encodeIfPresent(self.groupCount, forKey: "groupCount")
    }
  }
}
