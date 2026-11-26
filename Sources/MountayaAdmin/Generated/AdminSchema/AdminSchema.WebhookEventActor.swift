// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Who made the change a webhook event records.
  public struct WebhookEventActor: Sendable, Hashable, Codable {
    /// What kind of actor it is.
    public var type: AdminSchema.WebhookEventActorType
    /// Identifier of the person, when `type` is `user`. Absent on
    /// `organization.invitation.declined`: its actor is the person invited, whom the
    /// invitation names by the address it was sent to, and an organization is not told
    /// which account answers an invitation it made to an address.
    public var user_id: String?
    /// Identifier of the publishable key the request was made with: always when `type` is
    /// `key`, and when `type` is `user` and the person acted through a key rather than
    /// signed in to Mountaya's web application.
    public var key_id: String?

    /// Creates a `WebhookEventActor` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      type: AdminSchema.WebhookEventActorType,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.type = type
      self.user_id = nil
      self.key_id = nil
      configure(&self)
    }

    /// Reads a `WebhookEventActor` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.type = try container.decode(AdminSchema.WebhookEventActorType.self, forKey: "type")
      self.user_id = try container.decodeIfPresent(String.self, forKey: "user_id")
      self.key_id = try container.decodeIfPresent(String.self, forKey: "key_id")
    }

    /// Writes a `WebhookEventActor` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encodeIfPresent(self.user_id, forKey: "user_id")
      try container.encodeIfPresent(self.key_id, forKey: "key_id")
    }
  }
}
