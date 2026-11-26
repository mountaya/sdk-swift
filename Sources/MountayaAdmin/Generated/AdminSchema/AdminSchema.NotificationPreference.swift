// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Whether a member receives one notification email about an organization.
  public struct NotificationPreference: Sendable, Hashable, Codable {
    /// The notification.
    public var notification: AdminSchema.NotificationType
    /// Whether the member is sent it by email. On by default.
    public var email: Bool
    /// Whether the member may turn it off. A security notification is always
    /// sent, and is locked.
    public var locked: Bool
    /// Why it cannot be turned off, in the request's `Accept-Language`, null on
    /// a notification that can.
    public var locked_reason: String?

    /// Creates a `NotificationPreference` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      notification: AdminSchema.NotificationType,
      email: Bool,
      locked: Bool,
      locked_reason: String?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.notification = notification
      self.email = email
      self.locked = locked
      self.locked_reason = locked_reason
      configure(&self)
    }

    /// Reads a `NotificationPreference` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.notification = try container.decode(
        AdminSchema.NotificationType.self, forKey: "notification")
      self.email = try container.decode(Bool.self, forKey: "email")
      self.locked = try container.decode(Bool.self, forKey: "locked")
      self.locked_reason = try container.decodeIfPresent(String.self, forKey: "locked_reason")
    }

    /// Writes a `NotificationPreference` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.notification, forKey: "notification")
      try container.encode(self.email, forKey: "email")
      try container.encode(self.locked, forKey: "locked")
      try container.encodeNullable(self.locked_reason, forKey: "locked_reason")
    }
  }
}
