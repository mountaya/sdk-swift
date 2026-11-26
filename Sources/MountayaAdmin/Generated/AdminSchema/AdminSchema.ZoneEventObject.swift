// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A zone as a webhook event carries it: its identifiers, its name and description, its
  /// level, mode and validity window, its status, whether it is private, and its version.
  /// Its geometry and source are never carried: `getZone` reads them.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct ZoneEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `zone`: the family of the event types that
    /// carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `zone`, the discriminator value naming this member of its union.
    public var object: String {
      "zone"
    }
    /// Identifier of the zone.
    public var id: String
    /// Identifier of the organization the zone belongs to.
    public var organization_id: String
    /// The zone's name.
    public var name: String
    /// The zone's description, null when it has none.
    public var description: String?
    /// The zone's severity level.
    public var level: RestSchema.ZoneLevel
    /// How the zone's area was drawn.
    public var mode: RestSchema.ZoneMode
    /// Whether the zone has a live publication once this change was made.
    public var status: RestSchema.ZoneStatus
    /// Whether the zone is private to the organization.
    public var is_private: Bool
    /// When the zone's validity window opens, null when it has always been in force.
    public var start_at: Date?
    /// When the zone's validity window closes, null when it never lapses.
    public var end_at: Date?
    /// The zone's version once this change was made. It climbs with every change a read
    /// of the zone shows, so of two events about one zone the one carrying the higher
    /// `version` is the later state: events are not delivered in order. A delete is the
    /// zone's last version change: `zone.deleted` carries the version one past the last
    /// the zone held, so an event about it that arrives after its delete is never the
    /// later state.
    public var version: Int64
    /// The user who created the zone.
    public var created_by: RestSchema.RelationToUser
    /// When the zone was created.
    public var created_at: Date
    /// When the zone last changed.
    public var updated_at: Date

    /// Creates a `ZoneEventObject` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      name: String,
      description: String?,
      level: RestSchema.ZoneLevel,
      mode: RestSchema.ZoneMode,
      status: RestSchema.ZoneStatus,
      is_private: Bool,
      start_at: Date?,
      end_at: Date?,
      version: Int64,
      created_by: RestSchema.RelationToUser,
      created_at: Date,
      updated_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.name = name
      self.description = description
      self.level = level
      self.mode = mode
      self.status = status
      self.is_private = is_private
      self.start_at = start_at
      self.end_at = end_at
      self.version = version
      self.created_by = created_by
      self.created_at = created_at
      self.updated_at = updated_at
      configure(&self)
    }

    /// Reads a `ZoneEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.name = try container.decode(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.level = try container.decode(RestSchema.ZoneLevel.self, forKey: "level")
      self.mode = try container.decode(RestSchema.ZoneMode.self, forKey: "mode")
      self.status = try container.decode(RestSchema.ZoneStatus.self, forKey: "status")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.start_at = try container.decodeWiredIfPresent(Date.self, forKey: "start_at")
      self.end_at = try container.decodeWiredIfPresent(Date.self, forKey: "end_at")
      self.version = try container.decode(Int64.self, forKey: "version")
      self.created_by = try container.decode(RestSchema.RelationToUser.self, forKey: "created_by")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
    }

    /// Writes a `ZoneEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.name, forKey: "name")
      try container.encodeNullable(self.description, forKey: "description")
      try container.encode(self.level, forKey: "level")
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.status, forKey: "status")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encodeWiredNullable(self.start_at, forKey: "start_at")
      try container.encodeWiredNullable(self.end_at, forKey: "end_at")
      try container.encode(self.version, forKey: "version")
      try container.encode(self.created_by, forKey: "created_by")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
    }
  }
}
