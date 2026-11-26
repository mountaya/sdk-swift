// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A membership as a webhook event carries it: the member's account and the role they
  /// hold. The member's address and name are not carried: `getOrganizationMembers` lists
  /// them while they are a member.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct OrganizationMemberEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.member`: the family of the event
    /// types that carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `organization.member`, the discriminator value naming this member of its union.
    public var object: String {
      "organization.member"
    }
    /// Identifier of the member's account, the `user_id` that names them on
    /// `patchOrganizationMember` and `deleteOrganizationMember`.
    public var user_id: String
    /// The role the member holds once this change was made, or held when they left.
    public var role: RestSchema.OrganizationRole
    /// When the member joined the organization.
    public var joined_at: Date
    /// Why the membership ended. Present on `organization.member.deleted` alone.
    public var reason: AdminSchema.OrganizationMemberDeletionReason?

    /// Creates a `OrganizationMemberEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      user_id: String,
      role: RestSchema.OrganizationRole,
      joined_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      self.role = role
      self.joined_at = joined_at
      self.reason = nil
      configure(&self)
    }

    /// Reads a `OrganizationMemberEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.role = try container.decode(RestSchema.OrganizationRole.self, forKey: "role")
      self.joined_at = try container.decodeWired(Date.self, forKey: "joined_at")
      self.reason = try container.decodeIfPresent(
        AdminSchema.OrganizationMemberDeletionReason.self, forKey: "reason")
    }

    /// Writes a `OrganizationMemberEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.user_id, forKey: "user_id")
      try container.encode(self.role, forKey: "role")
      try container.encodeWired(self.joined_at, forKey: "joined_at")
      try container.encodeIfPresent(self.reason, forKey: "reason")
    }
  }
}
