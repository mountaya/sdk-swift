// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for creating a new zone annotation.
  public struct ZoneCreateParams: Sendable, Hashable, Codable {
    /// Free-text description of the zone, at most 100 characters as sent, stored
    /// with leading and trailing whitespace trimmed. Omit it, or send one that
    /// trims to nothing, to create the zone without one.
    public var description: String?
    /// End of the temporal validity window. Optional and not nullable: omit it
    /// for a zone with no expiration. One earlier than `start_at` is a `400`
    /// naming `end_at`.
    public var end_at: Date?
    /// The area of a zone drawn by hand. Provide exactly one of `geojson` or
    /// `source`. An `id` on the feature becomes the zone's id; one that another
    /// zone already has is a `409`.
    ///
    /// The ring rules stated on `GeoJSONPolygon` are enforced here. A ring whose
    /// ends differ, a ring of fewer than four positions, a polygon carrying no
    /// ring, and a position outside the angle ranges the feature's `geometry`
    /// states are each a `400` naming the ring or position at fault, and so is
    /// an area of more than 10,000 positions in total, naming `geojson`. An
    /// outline one meridian or one parallel crosses more than 512 times, every
    /// ring counted, is too intricate to be stored, and one that is not a valid
    /// polygon, in degrees as sent or once projected to Web Mercator, as a map
    /// draws it (a ring that crosses itself or another ring, a ring that
    /// touches itself, or a hole outside its shell), is refused too: each is a
    /// `400` naming `geojson.geometry`, without saying where.
    public var geojson: RestSchema.ZoneFeature?
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
    /// How the zone's area is drawn or computed. A zone given a `source` must be
    /// `polygon`; any other mode beside a `source` is a 400.
    public var mode: RestSchema.ZoneMode
    /// Display name of the zone, at most 30 characters as sent, and at least 2
    /// once leading and trailing whitespace is trimmed. Refused with a `409` when
    /// another zone in the organization already carries it. Names are compared
    /// exactly after trimming, case included, so `Alps` and `alps` are two
    /// different names. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var name: String
    /// Identifier of the organization that will own the zone. It must be the
    /// key's organization; omitted, it is that organization.
    public var organization_id: String?
    /// Provenance inputs for a computed zone. Provide exactly one of `geojson` or
    /// `source`; when `source` is given the zone's polygon is computed from these
    /// inputs and the source is kept, so the zone can be refreshed by sending it
    /// again on an update. An area computed from the source is held to every
    /// rule a drawn one is, its 10,000 positions included, and one that breaks
    /// any is a `400` naming `source`, and nothing is created.
    ///
    /// Optional and not nullable: send it for a computed zone, or leave it out
    /// and send `geojson`. The update operation types the same field nullable,
    /// because there `null` detaches an existing source and keeps the computed
    /// area as it stands.
    public var source: RestSchema.ZoneSource?
    /// Start of the temporal validity window. Optional and not nullable: omit it
    /// for a zone that is active immediately.
    public var start_at: Date?

    /// Creates a `ZoneCreateParams` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      is_private: Bool,
      level: RestSchema.ZoneLevel,
      mode: RestSchema.ZoneMode,
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.description = nil
      self.end_at = nil
      self.geojson = nil
      self.is_private = is_private
      self.level = level
      self.mode = mode
      self.name = name
      self.organization_id = nil
      self.source = nil
      self.start_at = nil
      configure(&self)
    }

    /// Reads a `ZoneCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.end_at = try container.decodeWiredIfPresent(Date.self, forKey: "end_at")
      self.geojson = try container.decodeIfPresent(RestSchema.ZoneFeature.self, forKey: "geojson")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.level = try container.decode(RestSchema.ZoneLevel.self, forKey: "level")
      self.mode = try container.decode(RestSchema.ZoneMode.self, forKey: "mode")
      self.name = try container.decode(String.self, forKey: "name")
      self.organization_id = try container.decodeIfPresent(String.self, forKey: "organization_id")
      self.source = try container.decodeIfPresent(RestSchema.ZoneSource.self, forKey: "source")
      self.start_at = try container.decodeWiredIfPresent(Date.self, forKey: "start_at")
    }

    /// Writes a `ZoneCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeWiredIfPresent(self.end_at, forKey: "end_at")
      try container.encodeIfPresent(self.geojson, forKey: "geojson")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encode(self.level, forKey: "level")
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.organization_id, forKey: "organization_id")
      try container.encodeIfPresent(self.source, forKey: "source")
      try container.encodeWiredIfPresent(self.start_at, forKey: "start_at")
    }
  }
}
