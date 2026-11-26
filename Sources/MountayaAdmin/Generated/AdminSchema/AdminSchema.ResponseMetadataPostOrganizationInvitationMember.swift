// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// ResponseMetadataPostOrganizationInvitationMember is an object the contract writes inline.
  public struct ResponseMetadataPostOrganizationInvitationMember: Sendable, Hashable, Codable {
    /// Identifier of the member, as a member listing carries it.
    public var user_id: String

    /// Creates a `ResponseMetadataPostOrganizationInvitationMember` from the properties the
    /// contract requires, the optional ones being set in `configure`.
    public init(
      user_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = user_id
      configure(&self)
    }

    /// Reads a `ResponseMetadataPostOrganizationInvitationMember` from the JSON object the contract
    /// describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decode(String.self, forKey: "user_id")
    }

    /// Writes a `ResponseMetadataPostOrganizationInvitationMember` as the JSON object the contract
    /// describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.user_id, forKey: "user_id")
    }
  }
}
