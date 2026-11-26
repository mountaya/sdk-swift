// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An invitation as the invited person reads it under `/v1/me/invitations`:
  /// which organization it is to, what that organization holds, and the role it
  /// grants. It is matched to the person by an address their account has
  /// verified, so an invitation to an address the account has not verified is
  /// not listed.
  public struct UserInvitation: Sendable, Hashable, Codable {
    /// Identifier of the invitation, which `postMyInvitationAccept` and
    /// `deleteMyInvitation` take.
    public var id: String
    /// Identifier of the organization the invitation is to.
    public var organization_id: String
    /// The organization's display name, as it appears to its members.
    public var organization_name: String
    /// The products the organization holds, as `Capability` members, each at
    /// most once and sorted alphabetically, so a person sees what an
    /// organization offers before answering. Empty when it holds none.
    public var organization_capabilities: [AdminSchema.Capability]
    /// The role accepting grants.
    public var role: AdminSchema.AssignableOrganizationRole
    /// When the invitation was made.
    public var created_at: Date
    /// When the invitation lapses unanswered, thirty days after it was made.
    public var expires_at: Date

    /// Creates a `UserInvitation` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      organization_name: String,
      organization_capabilities: [AdminSchema.Capability],
      role: AdminSchema.AssignableOrganizationRole,
      created_at: Date,
      expires_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.organization_name = organization_name
      self.organization_capabilities = organization_capabilities
      self.role = role
      self.created_at = created_at
      self.expires_at = expires_at
      configure(&self)
    }

    /// Reads a `UserInvitation` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.organization_name = try container.decode(String.self, forKey: "organization_name")
      self.organization_capabilities = try container.decode(
        [AdminSchema.Capability].self, forKey: "organization_capabilities")
      self.role = try container.decode(AdminSchema.AssignableOrganizationRole.self, forKey: "role")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.expires_at = try container.decodeWired(Date.self, forKey: "expires_at")
    }

    /// Writes a `UserInvitation` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.organization_name, forKey: "organization_name")
      try container.encode(self.organization_capabilities, forKey: "organization_capabilities")
      try container.encode(self.role, forKey: "role")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWired(self.expires_at, forKey: "expires_at")
    }
  }
}
