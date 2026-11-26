// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Somebody who has joined an organization, with the role they hold in it. An
  /// invitation that has not been accepted is not a member: it is an
  /// `OrganizationInvitation`, listed by `getOrganizationInvitations`.
  public struct OrganizationMember: Sendable, Hashable, Codable {
    /// Identifier of the member's account. It is what names them on
    /// `patchOrganizationMember` and `deleteOrganizationMember`, and the
    /// `user_id` a session token is minted for when a page acts as them.
    public var user_id: String
    /// The member's account address. Absent for a member whose account cannot
    /// be resolved at that moment, who is listed without it.
    public var email: String?
    /// The member's display name, present when the member has set one and their
    /// account can be resolved. Unbounded, unlike the name of a resource this
    /// API mints: it belongs to the person's account, and no operation here
    /// writes it.
    public var name: String?
    /// What the member may do in this organization.
    public var role: RestSchema.OrganizationRole
    /// When the member joined: when the invitation was accepted, or when the
    /// organization was created for its owner.
    public var joined_at: Date

    /// Creates a `OrganizationMember` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      user_id: String,
      role: RestSchema.OrganizationRole,
      joined_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      self.email = nil
      self.name = nil
      self.role = role
      self.joined_at = joined_at
      configure(&self)
    }

    /// Reads a `OrganizationMember` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.email = try container.decodeIfPresent(String.self, forKey: "email")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.role = try container.decode(RestSchema.OrganizationRole.self, forKey: "role")
      self.joined_at = try container.decodeWired(Date.self, forKey: "joined_at")
    }

    /// Writes a `OrganizationMember` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.user_id, forKey: "user_id")
      try container.encodeIfPresent(self.email, forKey: "email")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encode(self.role, forKey: "role")
      try container.encodeWired(self.joined_at, forKey: "joined_at")
    }
  }
}
