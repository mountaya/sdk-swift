// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What a refused invitation conflicts with, at `extensions.metadata` of the
  /// `409` of `postOrganizationInvitation`. Exactly one of the two is present:
  /// `member` when the address already belongs to a member of the organization,
  /// and `invitation` when an invitation to it is already waiting for an answer.
  public struct ResponseMetadataPostOrganizationInvitation: Sendable, Hashable, Codable {
    /// The member whose account carries the address.
    public var member: AdminSchema.ResponseMetadataPostOrganizationInvitationMember?
    /// The invitation already waiting for an answer.
    public var invitation: AdminSchema.ResponseMetadataPostOrganizationInvitationInvitation?

    /// Creates a `ResponseMetadataPostOrganizationInvitation` from the properties the contract
    /// requires, the optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.member = nil
      self.invitation = nil
      configure(&self)
    }

    /// Reads a `ResponseMetadataPostOrganizationInvitation` from the JSON object the contract
    /// describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.member = try container.decodeIfPresent(
        AdminSchema.ResponseMetadataPostOrganizationInvitationMember.self, forKey: "member")
      self.invitation = try container.decodeIfPresent(
        AdminSchema.ResponseMetadataPostOrganizationInvitationInvitation.self, forKey: "invitation")
    }

    /// Writes a `ResponseMetadataPostOrganizationInvitation` as the JSON object the contract
    /// describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.member, forKey: "member")
      try container.encodeIfPresent(self.invitation, forKey: "invitation")
    }
  }
}
