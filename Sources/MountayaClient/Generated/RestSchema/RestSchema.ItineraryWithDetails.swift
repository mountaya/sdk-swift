// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// An itinerary with its full list of segments, waypoints, and segment groups
  /// included, plus its derived publication state.
  public struct ItineraryWithDetails: Sendable, Hashable, Codable {
    /// Identifier of the activity type for the whole itinerary. Set at creation
    /// and immutable; every segment shares this activity.
    public var activity_id: String
    /// Total elevation gain across all of the itinerary's segments, in meters
    /// (the sum of each segment's ascent). Matches the unit of
    /// ItinerarySegment.ascent. Null when no segment contributes an ascent value
    /// (e.g. the itinerary has no segments, or none carry elevation data).
    public var ascent: Int?
    /// How many segments and waypoints the itinerary holds. A summary count, so a
    /// client can size a list without fetching the details.
    public var count: RestSchema.ItineraryCount
    /// Timestamp of the itinerary's creation.
    public var created_at: Date
    /// The user who created the itinerary. It is the author rather than the last
    /// editor, and it does not move when another member edits the itinerary.
    public var created_by: RestSchema.RelationToUser
    /// Free-text description of the itinerary. Null when it has none.
    public var description: String?
    /// Total distance across all of the itinerary's segments, in meters (the sum
    /// of each segment's distance). Matches the unit and measurement basis of
    /// ItinerarySegment.distance, so segments routed through waypoints and drawn
    /// freehand sum to a single comparable quantity. Null when no segment
    /// contributes a distance value (e.g. the itinerary has no segments, or none
    /// have been computed).
    public var distance: Double?
    /// Unique identifier of the itinerary.
    public var id: String
    /// Whether the itinerary is private. A private itinerary is reached only with
    /// the key of the organization that owns it, so a private personal itinerary,
    /// owned by no organization, is reached by no key. A public itinerary is
    /// readable by id, read-only, by any publishable key, as last published, and
    /// it is listed only in its own organization's listings. A share token
    /// reaches only what its link names, the itinerary or a collection holding
    /// it, and reaches it whatever this says. Public never grants editing, which
    /// takes a write role in the owning organization. Privacy is read from the
    /// draft, so a change takes effect at once rather than at the next publish.
    public var is_private: Bool
    /// Whether the itinerary has been verified by the organization.
    public var is_verified: Bool
    /// Display name of the itinerary.
    public var name: String
    /// Identifier of the organization that owns this itinerary. Null for a personal
    /// itinerary, made from an individual account and owned by no organization.
    public var organization_id: String?
    /// The version of everything a read of this itinerary returns, the one
    /// the `ETag` of that read carries, opaque and compared whole. Unlike
    /// `revision`, it moves on every write that changes the read: the
    /// itinerary's own fields, a segment, segment group or waypoint, a merge,
    /// split or convert, and a publish or unpublish, so a client holding it
    /// knows whether anything it shows is stale. A share link minted or
    /// revoked leaves it where it is. A draft read and a read served the
    /// published snapshot carry different tags. Send it as `If-Match` to make
    /// a write to the itinerary conditional.
    public var etag: String
    /// Revision number of the itinerary's own fields: 1 at creation, and raised
    /// by every accepted `patchItinerary`, even one that changes nothing. Edits
    /// to its segments, waypoints and groups leave it where it is, since each of
    /// those carries a `revision` of its own. On a read served the published
    /// snapshot it is the publication number instead. A consumer holding an
    /// older copy compares it with the `revision` a change frame carries; no
    /// request takes it.
    public var revision: Int
    /// Whether the itinerary is published right now, that is whether it has a
    /// live publication. Derived server-side; read-only and never accepted as an
    /// input. Taking an itinerary down returns it to `draft`, although its
    /// publication number is kept, so a later publish takes the next one. Note
    /// this is independent of is_private: a draft is invisible on the public
    /// surfaces however public its privacy setting says it is.
    ///
    /// It sits on the itinerary rather than on the detailed read because it is a
    /// fact about the resource rather than about the publication serving it. A
    /// listing is where a client decides whether to offer withdrawal, and one
    /// that had to fetch each itinerary in full to find that out would be making
    /// a request per itinerary to render a menu. The other two derived fields
    /// (published_at and has_unpublished_changes) describe the publication
    /// relative to the draft and stay with the detailed read, which is the one
    /// that serves it.
    public var status: RestSchema.ItineraryStatus
    /// Timestamp of the itinerary's last change, counting changes to its
    /// segments, segment groups and waypoints, a deletion among them. Always
    /// present: it equals `created_at` until the itinerary is first changed.
    public var updated_at: Date
    /// Segment groups defined on this itinerary. Flat, not nested inside the
    /// segments: the ordered segment chain stays the primary structure, and
    /// each segment points back at its group through its group_id. Empty when
    /// the itinerary has no groups.
    public var groups: [RestSchema.ItinerarySegmentGroup]
    /// Whether the draft has been edited since the last publish, so the public
    /// surfaces are serving something older than what the studio shows. Derived
    /// server-side by comparing the itinerary's updated_at against its latest
    /// publication; read-only and never accepted as an input. Every write to
    /// the itinerary, its segments, its segment groups and its waypoints moves
    /// updated_at, a deletion among them, so each of those edits sets it.
    /// Always false while status is draft. status itself is on Itinerary, so a
    /// listing answers "is this live" without this read.
    ///
    /// The server writes it, and a request never sends it.
    public var has_unpublished_changes: Bool
    /// Timestamp of the itinerary's live publication, or null when it has none:
    /// when it has never been published, or has been taken down. Derived
    /// server-side: publishing is the only thing that sets it, taking the
    /// itinerary down clears it, and it is never accepted as an input.
    ///
    /// The server writes it, and a request never sends it.
    public var published_at: Date?
    /// Ordered list of segments belonging to this itinerary.
    public var segments: [RestSchema.ItinerarySegment]
    /// Ordered list of waypoints belonging to this itinerary.
    public var waypoints: [RestSchema.ItineraryWaypoint]

    /// Creates a `ItineraryWithDetails` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      activity_id: String,
      ascent: Int?,
      count: RestSchema.ItineraryCount,
      created_at: Date,
      created_by: RestSchema.RelationToUser,
      description: String?,
      distance: Double?,
      id: String,
      is_private: Bool,
      is_verified: Bool,
      name: String,
      organization_id: String?,
      etag: String,
      revision: Int,
      status: RestSchema.ItineraryStatus,
      updated_at: Date,
      groups: [RestSchema.ItinerarySegmentGroup],
      has_unpublished_changes: Bool,
      published_at: Date?,
      segments: [RestSchema.ItinerarySegment],
      waypoints: [RestSchema.ItineraryWaypoint],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.activity_id = activity_id
      self.ascent = ascent
      self.count = count
      self.created_at = created_at
      self.created_by = created_by
      self.description = description
      self.distance = distance
      self.id = id
      self.is_private = is_private
      self.is_verified = is_verified
      self.name = name
      self.organization_id = organization_id
      self.etag = etag
      self.revision = revision
      self.status = status
      self.updated_at = updated_at
      self.groups = groups
      self.has_unpublished_changes = has_unpublished_changes
      self.published_at = published_at
      self.segments = segments
      self.waypoints = waypoints
      configure(&self)
    }

    /// Reads a `ItineraryWithDetails` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.activity_id = try container.decode(String.self, forKey: "activity_id")
      self.ascent = try container.decodeIfPresent(Int.self, forKey: "ascent")
      self.count = try container.decode(RestSchema.ItineraryCount.self, forKey: "count")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.distance = try container.decodeIfPresent(Double.self, forKey: "distance")
      self.id = try container.decode(String.self, forKey: "id")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.is_verified = try container.decode(Bool.self, forKey: "is_verified")
      self.name = try container.decode(String.self, forKey: "name")
      self.organization_id = try container.decodeIfPresent(String.self, forKey: "organization_id")
      self.etag = try container.decode(String.self, forKey: "etag")
      self.revision = try container.decode(Int.self, forKey: "revision")
      self.status = try container.decode(RestSchema.ItineraryStatus.self, forKey: "status")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
      self.groups = try container.decode([RestSchema.ItinerarySegmentGroup].self, forKey: "groups")
      self.has_unpublished_changes = try container.decode(
        Bool.self, forKey: "has_unpublished_changes")
      self.published_at = try container.decodeWiredIfPresent(Date.self, forKey: "published_at")
      self.segments = try container.decode([RestSchema.ItinerarySegment].self, forKey: "segments")
      self.waypoints = try container.decode(
        [RestSchema.ItineraryWaypoint].self, forKey: "waypoints")
    }

    /// Writes a `ItineraryWithDetails` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.activity_id, forKey: "activity_id")
      try container.encodeNullable(self.ascent, forKey: "ascent")
      try container.encode(self.count, forKey: "count")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encodeNullable(self.distance, forKey: "distance")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encode(self.is_verified, forKey: "is_verified")
      try container.encode(self.name, forKey: "name")
      try container.encodeNullable(self.organization_id, forKey: "organization_id")
      try container.encode(self.etag, forKey: "etag")
      try container.encode(self.revision, forKey: "revision")
      try container.encode(self.status, forKey: "status")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
      try container.encode(self.groups, forKey: "groups")
      try container.encode(self.has_unpublished_changes, forKey: "has_unpublished_changes")
      try container.encodeWiredNullable(self.published_at, forKey: "published_at")
      try container.encode(self.segments, forKey: "segments")
      try container.encode(self.waypoints, forKey: "waypoints")
    }
  }
}
