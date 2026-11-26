// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Which notification emails about an organization a member receives. A
  /// member is sent each one unless they turned it off, and a security
  /// notification is always sent.
  public struct NotificationPreferences: Sendable, Hashable, Codable {
    /// Identifier of the organization the notifications are about.
    public var organization_id: String
    /// Identifier of the member, the user the session token names.
    public var user_id: String
    /// One entry per notification the member can receive in the organization:
    /// the security notifications, `member-role-changed` and `member-removed`,
    /// locked on; `collection-deleted`; and for an owner or an admin,
    /// `webhook-endpoint-failing` and `webhook-endpoint-disabled`. The
    /// `invitation` email goes to an address before it is a member's, and is
    /// never listed.
    public var notifications: [AdminSchema.NotificationPreference]

    /// Creates a `NotificationPreferences` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      organization_id: String,
      user_id: String,
      notifications: [AdminSchema.NotificationPreference],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.organization_id = organization_id
      self.user_id = user_id
      self.notifications = notifications
      configure(&self)
    }

    /// Reads a `NotificationPreferences` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.user_id = try container.decode(String.self, forKey: "user_id")
      self.notifications = try container.decode(
        [AdminSchema.NotificationPreference].self, forKey: "notifications")
    }

    /// Writes a `NotificationPreferences` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.user_id, forKey: "user_id")
      try container.encode(self.notifications, forKey: "notifications")
    }
  }
}
