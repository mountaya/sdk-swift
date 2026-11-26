// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// An organization: the workspace itineraries, zones and collections belong to,
  /// together with the settings that shape its embeds. What the organization's
  /// agreement entitles it to is not part of it: the products a person's
  /// organizations hold are read as `organization_capabilities` on
  /// `getMyOrganizations`, and the one entitlement an embed paints by is
  /// `white_label`, which every read carries.
  public struct Organization: Sendable, Hashable, Codable {
    /// Timestamp of the organization's creation.
    public var created_at: Date
    /// The version of the organization's own fields, the one the `ETag` of a
    /// read of it carries, opaque and compared whole. Send it as `If-Match` to
    /// make `patchOrganization` conditional. A change to the settings moves
    /// the settings' own `etag` and not this one, so a rename and a settings
    /// edit made at the same moment never refuse each other.
    public var etag: String
    /// Identifier of the organization, and the value every `{organization_id}`
    /// path takes.
    public var id: String
    /// Display name of the organization.
    public var name: String
    /// Whether the organization was created to be covered by an agreement with
    /// Mountaya, which `agreement_requested` on `postOrganization` asks for,
    /// and no agreement has been set for it. It reads false again once one is.
    /// It never grants anything: an organization awaiting its agreement holds
    /// no product, and it is the agreement, once set, that grants the products
    /// it names. It tells a client to wait for the agreement rather than to ask
    /// for a card.
    public var awaiting_agreement: Bool
    /// The settings that shape the organization's embeds. They are changed
    /// through `patchOrganizationSettings` rather than through an organization
    /// update.
    public var settings: RestSchema.OrganizationSettings
    /// Timestamp of the organization's last change. Always present: it equals
    /// `created_at` until the organization is first changed.
    public var updated_at: Date
    /// Whether the organization may suppress the Mountaya mark on its embedded
    /// maps and exported video, which its agreement decides. It is the one
    /// entitlement this contract returns on the organization, so an embed
    /// decides whether to paint the mark from the read it already makes. When
    /// it cannot be read at that moment it reads `false`, which paints the
    /// mark.
    ///
    /// It never suppresses tile attribution. MapTiler, OpenStreetMap and
    /// meteoblue credits are a licence obligation and stay on every map,
    /// whatever the organization holds.
    public var white_label: Bool

    /// Creates a `Organization` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      created_at: Date,
      etag: String,
      id: String,
      name: String,
      awaiting_agreement: Bool,
      settings: RestSchema.OrganizationSettings,
      updated_at: Date,
      white_label: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.created_at = created_at
      self.etag = etag
      self.id = id
      self.name = name
      self.awaiting_agreement = awaiting_agreement
      self.settings = settings
      self.updated_at = updated_at
      self.white_label = white_label
      configure(&self)
    }

    /// Reads a `Organization` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.etag = try container.decode(String.self, forKey: "etag")
      self.id = try container.decode(String.self, forKey: "id")
      self.name = try container.decode(String.self, forKey: "name")
      self.awaiting_agreement = try container.decode(Bool.self, forKey: "awaiting_agreement")
      self.settings = try container.decode(RestSchema.OrganizationSettings.self, forKey: "settings")
      self.updated_at = try container.decodeWired(Date.self, forKey: "updated_at")
      self.white_label = try container.decode(Bool.self, forKey: "white_label")
    }

    /// Writes a `Organization` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encode(self.etag, forKey: "etag")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.awaiting_agreement, forKey: "awaiting_agreement")
      try container.encode(self.settings, forKey: "settings")
      try container.encodeWired(self.updated_at, forKey: "updated_at")
      try container.encode(self.white_label, forKey: "white_label")
    }
  }
}
