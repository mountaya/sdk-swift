// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// OrganizationBillingSubscriptionUpdatedPreviousAttributes is the former value of each field a
  /// `organization.billing.subscription.updated` event's change moved, as its
  /// `data.previous_attributes` carries them, each typed as
  /// `AdminSchema.OrganizationSubscriptionEventObject` types it: a field the change did not move is
  /// nil.
  public struct OrganizationBillingSubscriptionUpdatedPreviousAttributes: Sendable, Hashable,
    Codable
  {
    /// The subscription's status once this change was made.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var status: AdminSchema.SubscriptionStatus?
    /// Whether the subscription ends when its current period does.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var cancel_at_period_end: Bool?
    /// When the subscription's current period ends.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var current_period_end_at: Date?

    /// Creates a `OrganizationBillingSubscriptionUpdatedPreviousAttributes` from the properties the
    /// contract requires, the optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.status = nil
      self.cancel_at_period_end = nil
      self.current_period_end_at = nil
      configure(&self)
    }

    /// Reads a `OrganizationBillingSubscriptionUpdatedPreviousAttributes` from the JSON object the
    /// contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.status = try container.decodeIfPresent(
        AdminSchema.SubscriptionStatus.self, forKey: "status")
      self.cancel_at_period_end = try container.decodeIfPresent(
        Bool.self, forKey: "cancel_at_period_end")
      self.current_period_end_at = try container.decodeWiredIfPresent(
        Date.self, forKey: "current_period_end_at")
    }

    /// Writes a `OrganizationBillingSubscriptionUpdatedPreviousAttributes` as the JSON object the
    /// contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.status, forKey: "status")
      try container.encodeIfPresent(self.cancel_at_period_end, forKey: "cancel_at_period_end")
      try container.encodeWiredIfPresent(
        self.current_period_end_at, forKey: "current_period_end_at")
    }
  }
}
