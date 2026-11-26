// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An invitation to join an organization, held by an email address until the
  /// person it names accepts or declines it, somebody withdraws it, or it
  /// expires. It holds a seat from the moment it is made until then.
  ///
  /// It names the address and never an account: whether an account carries the
  /// address is not part of any answer, so an invitation reads the same whether
  /// or not the person has signed up. The person finds it, once their account
  /// has verified the address, through `getMyInvitations`.
  public struct OrganizationInvitation: Sendable, Hashable, Codable {
    /// Identifier of the invitation. It is what `getOrganizationInvitation` and
    /// `deleteOrganizationInvitation` take, and what the invited person accepts
    /// or declines under `/v1/me/invitations`.
    public var id: String
    /// The address invited, as stored: trimmed and lowercased.
    public var email: String
    /// The role the person holds once they accept. `owner` is not among the
    /// values: it is never granted by invitation.
    public var role: AdminSchema.AssignableOrganizationRole
    /// The member who made the invitation.
    public var invited_by: RestSchema.RelationToUser
    /// When the invitation was made.
    public var created_at: Date
    /// When the invitation lapses unanswered, thirty days after it was made.
    /// An expired invitation frees its seat and is listed nowhere, and the
    /// address may be invited again.
    public var expires_at: Date

    /// Creates a `OrganizationInvitation` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      id: String,
      email: String,
      role: AdminSchema.AssignableOrganizationRole,
      invited_by: RestSchema.RelationToUser,
      created_at: Date,
      expires_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.email = email
      self.role = role
      self.invited_by = invited_by
      self.created_at = created_at
      self.expires_at = expires_at
      configure(&self)
    }

    /// Reads a `OrganizationInvitation` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.email = try container.decode(String.self, forKey: "email")
      self.role = try container.decode(AdminSchema.AssignableOrganizationRole.self, forKey: "role")
      self.invited_by = try container.decode(RestSchema.RelationToUser.self, forKey: "invited_by")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.expires_at = try container.decodeWired(Date.self, forKey: "expires_at")
    }

    /// Writes a `OrganizationInvitation` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.email, forKey: "email")
      try container.encode(self.role, forKey: "role")
      try container.encode(self.invited_by, forKey: "invited_by")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWired(self.expires_at, forKey: "expires_at")
    }
  }
}
