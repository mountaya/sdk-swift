// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A geographic annotation drawn on the map, such as a hazard zone, an
  /// information marker, or a custom area.
  public struct Zone: Sendable, Hashable, Codable {
    /// Timestamp of the zone's creation.
    public var created_at: Date
    /// The user who created the zone. It is the author rather than the last
    /// editor, and it does not move when another member edits the zone.
    public var created_by: RestSchema.RelationToUser
    /// Free-text description of the zone. Null when it has none.
    public var description: String?
    /// End of the temporal validity window. After this time the zone is not in
    /// force. Null when the zone has no expiration.
    public var end_at: Date?
    /// The version of everything a read of this zone returns, the one the
    /// `ETag` of that read carries, opaque and compared whole. It moves on
    /// every write to the zone and on a publish or unpublish, so a client
    /// holding it knows whether anything it shows is stale. A draft read and a
    /// read served the published snapshot carry different tags. Send it as
    /// `If-Match` to make `patchZone`, `deleteZone`, `postZonePublication` or
    /// `deleteZonePublication` conditional.
    public var etag: String
    /// The zone's area, as a GeoJSON Feature whose `id` is the zone id. On a
    /// sourced zone this is the polygon the source computed, not the inputs that
    /// produced it; `source` carries those.
    public var geojson: RestSchema.ZoneFeature
    /// Whether the draft has been edited since the last publish, so the public
    /// surfaces are serving something older than what the studio shows.
    /// Derived server-side by comparing the zone's updated_at against its
    /// latest publication; read-only and never accepted as an input. Always
    /// false while status is draft.
    ///
    /// The server writes it, and a request never sends it.
    public var has_unpublished_changes: Bool
    /// Unique identifier of the zone.
    public var id: String
    /// Whether the zone is private. A private zone is reached only with the key
    /// of the organization that owns it, so a private personal zone, owned by no
    /// organization, is reached by no key. A public zone is readable by id,
    /// read-only, by any publishable key, as last published, and it is listed
    /// only in its own organization's listings. A collection's share token
    /// reaches the zones that collection holds whatever this says. Public never
    /// grants editing, which takes a write role in the owning organization.
    /// Privacy is read from the draft, so a change takes effect at once rather
    /// than at the next publish.
    public var is_private: Bool
    /// How serious the zone is, which is what a renderer picks its styling from.
    /// It carries no access meaning: a zone is visible or not by `is_private`
    /// and its publication, never by its level.
    public var level: RestSchema.ZoneLevel
    /// How the zone's area was drawn or computed. A zone computed from `source`
    /// is `polygon`.
    public var mode: RestSchema.ZoneMode
    /// Display name of the zone.
    public var name: String
    /// Identifier of the organization that owns this zone. Null for a personal
    /// zone, made from an individual account and owned by no organization.
    public var organization_id: String?
    /// Timestamp of the zone's live publication, or null when it has none: when
    /// it has never been published, or has been taken down. Derived
    /// server-side: publishing is the only thing that sets it, taking the zone
    /// down clears it, and it is never accepted as an input.
    ///
    /// The server writes it, and a request never sends it.
    public var published_at: Date?
    /// Revision number of the zone, incremented by every `patchZone`, even one
    /// that changes nothing. Publishing and unpublishing leave it where it is.
    /// On a read served the published snapshot it is the publication number
    /// instead. A consumer holding an older copy compares it with the
    /// `revision` a change frame carries; no request takes it.
    public var revision: Int
    /// Provenance of the zone's geometry. Populated for a computed zone and null
    /// for a zone drawn by hand. The polygon is computed from these inputs on
    /// create and recomputed only by a `patchZone` that sends `source`. A
    /// `patchZone` sending `geojson` replaces the area and clears this, one
    /// sending `source: null` clears it and keeps the area, and every other
    /// write keeps both.
    public var source: RestSchema.ZoneSource?
    /// Start of the temporal validity window. Before this time the zone is not in
    /// force. Null when the zone is in force at once.
    public var start_at: Date?
    /// Whether the zone is published right now, that is whether it has a live
    /// publication. Derived server-side; read-only and never accepted as an
    /// input. Taking a zone down returns it to `draft`, although its publication
    /// number is kept, so a later publish takes the next one. Note this is
    /// independent of is_private: a draft is invisible on the public surfaces
    /// however public its privacy setting says it is.
    public var status: RestSchema.ZoneStatus
    /// When the zone's latest revision was written. Every `patchZone` moves it,
    /// even one that changes nothing. Always present: it equals `created_at`
    /// until the first patch.
    public var updated_at: Date

    /// Creates a `Zone` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      created_at: Date,
      created_by: RestSchema.RelationToUser,
      description: String?,
      end_at: Date?,
      etag: String,
      geojson: RestSchema.ZoneFeature,
      has_unpublished_changes: Bool,
      id: String,
      is_private: Bool,
      level: RestSchema.ZoneLevel,
      mode: RestSchema.ZoneMode,
      name: String,
      organization_id: String?,
      published_at: Date?,
      revision: Int,
      source: RestSchema.ZoneSource?,
      start_at: Date?,
      status: RestSchema.ZoneStatus,
      updated_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.created_at = created_at
      self.created_by = created_by
      self.description = description
      self.end_at = end_at
      self.etag = etag
      self.geojson = geojson
      self.has_unpublished_changes = has_unpublished_changes
      self.id = id
      self.is_private = is_private
      self.level = level
      self.mode = mode
      self.name = name
      self.organization_id = organization_id
      self.published_at = published_at
      self.revision = revision
      self.source = source
      self.start_at = start_at
      self.status = status
      self.updated_at = updated_at
      configure(&self)
    }

    /// Reads a `Zone` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.end_at = try container.decodeWiredIfPresent(Date.self, forKey: "end_at")
      self.etag = try container.decode(String.self, forKey: "etag")
      self.geojson = try container.decode(RestSchema.ZoneFeature.self, forKey: "geojson")
      self.has_unpublished_changes = try container.decode(
        Bool.self, forKey: "has_unpublished_changes")
      self.id = try container.decode(String.self, forKey: "id")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.level = try container.decode(RestSchema.ZoneLevel.self, forKey: "level")
      self.mode = try container.decode(RestSchema.ZoneMode.self, forKey: "mode")
      self.name = try container.decode(String.self, forKey: "name")
      self.organization_id = try container.decodeIfPresent(String.self, forKey: "organization_id")
      self.published_at = try container.decodeWiredIfPresent(Date.self, forKey: "published_at")
      self.revision = try container.decode(Int.self, forKey: "revision")
      self.source = try container.decodeIfPresent(RestSchema.ZoneSource.self, forKey: "source")
      self.start_at = try container.decodeWiredIfPresent(Date.self, forKey: "start_at")
      self.status = try container.decode(RestSchema.ZoneStatus.self, forKey: "status")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
    }

    /// Writes a `Zone` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encodeWiredNullable(self.end_at, forKey: "end_at")
      try container.encode(self.etag, forKey: "etag")
      try container.encode(self.geojson, forKey: "geojson")
      try container.encode(self.has_unpublished_changes, forKey: "has_unpublished_changes")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encode(self.level, forKey: "level")
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.name, forKey: "name")
      try container.encodeNullable(self.organization_id, forKey: "organization_id")
      try container.encodeWiredNullable(self.published_at, forKey: "published_at")
      try container.encode(self.revision, forKey: "revision")
      try container.encodeNullable(self.source, forKey: "source")
      try container.encodeWiredNullable(self.start_at, forKey: "start_at")
      try container.encode(self.status, forKey: "status")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
    }
  }
}
