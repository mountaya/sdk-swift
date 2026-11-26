// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A person's membership of one organization they have joined. It pairs the
  /// person and the organization, so it has no identifier of its own and names
  /// both: `user_id` and `organization_id`. It carries the organization's
  /// identity with the role, so a client can name the organization and read the
  /// person's role in it without a second read.
  ///
  /// It is not a trimmed `Organization`: this one is about a PERSON's
  /// relationship to an organization. It carries the products the organization
  /// holds, so a client can tell whether the organization holds Map Studio
  /// without reading the organization itself, and what that person may use of
  /// Map Studio there, in `studio_entitlements`, which Mountaya resolves from the
  /// organization's agreement and the member's role, so a studio shows what the
  /// agreement covers without deciding it itself. An invitation waiting for an
  /// answer is not a membership: it is a `UserInvitation`.
  public struct Membership: Sendable, Hashable, Codable {
    /// Identifier of the person, the user the session token names.
    public var user_id: String
    /// Identifier of the organization. It is what every organization-scoped
    /// operation takes as its `organization_id` path parameter.
    public var organization_id: String
    /// The organization's display name, as it appears to its members.
    public var organization_name: String
    /// The products the organization holds, as `Capability` members, each at
    /// most once and sorted alphabetically. Empty when it holds none, as a new
    /// organization does. It is what the organization holds, never what this
    /// member may do with it: the role and `studio_entitlements` say that.
    public var organization_capabilities: [AdminSchema.Capability]
    /// What this person may use of Map Studio in this organization, as
    /// `StudioEntitlement` members, each at most once and sorted
    /// alphabetically. Mountaya resolves it from what the organization holds
    /// and from the role, as `StudioEntitlement` describes: `embed`,
    /// `publish`, `video-export` and `video-organization-modes` only where the
    /// organization holds Map Publishing, and `white-label` only where it holds
    /// White label. A change of agreement or of role reaches it on the
    /// next read. Read with a publishable key, it is narrowed by the
    /// organization's safety rules, as what the key is served is:
    /// `profile-insights` only when `with_profile_analysis` is set, `map-pois`
    /// only when `with_overlays` admits the points of interest, and
    /// `map-overlays` only when it admits another overlay. It authorizes
    /// nothing by itself, since every request is still refused by its own rule.
    public var studio_entitlements: [RestSchema.StudioEntitlement]
    /// What this person may do in this organization.
    public var role: RestSchema.OrganizationRole
    /// When the person joined: when the invitation was accepted, or when the
    /// organization was created for its owner.
    public var joined_at: Date

    /// Creates a `Membership` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      user_id: String,
      organization_id: String,
      organization_name: String,
      organization_capabilities: [AdminSchema.Capability],
      studio_entitlements: [RestSchema.StudioEntitlement],
      role: RestSchema.OrganizationRole,
      joined_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      self.organization_id = organization_id
      self.organization_name = organization_name
      self.organization_capabilities = organization_capabilities
      self.studio_entitlements = studio_entitlements
      self.role = role
      self.joined_at = joined_at
      configure(&self)
    }

    /// Reads a `Membership` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.organization_name = try container.decode(String.self, forKey: "organization_name")
      self.organization_capabilities = try container.decode(
        [AdminSchema.Capability].self, forKey: "organization_capabilities")
      self.studio_entitlements = try container.decode(
        [RestSchema.StudioEntitlement].self, forKey: "studio_entitlements")
      self.role = try container.decode(RestSchema.OrganizationRole.self, forKey: "role")
      self.joined_at = try container.decodeWired(Date.self, forKey: "joined_at")
    }

    /// Writes a `Membership` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.user_id, forKey: "user_id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.organization_name, forKey: "organization_name")
      try container.encode(self.organization_capabilities, forKey: "organization_capabilities")
      try container.encode(self.studio_entitlements, forKey: "studio_entitlements")
      try container.encode(self.role, forKey: "role")
      try container.encodeWired(self.joined_at, forKey: "joined_at")
    }
  }
}
