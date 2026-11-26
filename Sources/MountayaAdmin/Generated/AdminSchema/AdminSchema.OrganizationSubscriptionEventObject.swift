// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An organization's Data API subscription as a webhook event carries it: its
  /// identifier, its status, whether it is paused, and when its period ends.
  /// `getOrganizationBillingSubscription` reads its items and discount.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct OrganizationSubscriptionEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.billing.subscription`: the family
    /// of the event types that carry it, and what tells the members of
    /// `WebhookEventObject` apart.
    ///
    /// It is always `organization.billing.subscription`, the discriminator value naming this member
    /// of its union.
    public var object: String {
      "organization.billing.subscription"
    }
    /// Identifier of the subscription, the payment provider's `sub_` identifier. It is
    /// not a UUID. An organization holds one Data API subscription at a time, and one
    /// opened after another ended carries another identifier: the events of one
    /// subscription share it.
    public var id: String
    /// Identifier of the organization the subscription belongs to.
    public var organization_id: String
    /// The subscription's status once this change was made.
    public var status: AdminSchema.SubscriptionStatus
    /// Whether collection on the subscription is paused.
    public var paused: Bool
    /// Whether the subscription ends when its current period does.
    public var cancel_at_period_end: Bool
    /// When the subscription's current period ends.
    public var current_period_end_at: Date

    /// Creates a `OrganizationSubscriptionEventObject` from the properties the contract requires,
    /// the optional ones being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      status: AdminSchema.SubscriptionStatus,
      paused: Bool,
      cancel_at_period_end: Bool,
      current_period_end_at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.status = status
      self.paused = paused
      self.cancel_at_period_end = cancel_at_period_end
      self.current_period_end_at = current_period_end_at
      configure(&self)
    }

    /// Reads a `OrganizationSubscriptionEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.status = try container.decode(AdminSchema.SubscriptionStatus.self, forKey: "status")
      self.paused = try container.decode(Bool.self, forKey: "paused")
      self.cancel_at_period_end = try container.decode(Bool.self, forKey: "cancel_at_period_end")
      self.current_period_end_at = try container.decodeWired(
        Date.self, forKey: "current_period_end_at")
    }

    /// Writes a `OrganizationSubscriptionEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.status, forKey: "status")
      try container.encode(self.paused, forKey: "paused")
      try container.encode(self.cancel_at_period_end, forKey: "cancel_at_period_end")
      try container.encodeWired(self.current_period_end_at, forKey: "current_period_end_at")
    }
  }
}
