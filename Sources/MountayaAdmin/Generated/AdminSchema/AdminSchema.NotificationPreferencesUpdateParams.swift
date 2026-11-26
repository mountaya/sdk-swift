// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The notification emails to turn on or off. A notification left out keeps
  /// its setting.
  public struct NotificationPreferencesUpdateParams: Sendable, Hashable, Codable {
    /// One entry per notification to set, at least one, each notification at
    /// most once: naming one twice is a `400` naming the second.
    public var notifications: [AdminSchema.NotificationPreferenceUpdate]

    /// Creates a `NotificationPreferencesUpdateParams` from the properties the contract requires,
    /// the optional ones being set in `configure`.
    public init(
      notifications: [AdminSchema.NotificationPreferenceUpdate],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.notifications = notifications
      configure(&self)
    }

    /// Reads a `NotificationPreferencesUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.notifications = try container.decode(
        [AdminSchema.NotificationPreferenceUpdate].self, forKey: "notifications")
    }

    /// Writes a `NotificationPreferencesUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.notifications, forKey: "notifications")
    }
  }
}
