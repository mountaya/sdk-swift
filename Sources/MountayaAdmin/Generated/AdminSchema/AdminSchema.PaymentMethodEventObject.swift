// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A payment method as a webhook event carries it: its identifier and whether it is the
  /// one the organization is charged on. `getOrganizationBillingPaymentMethods` reads its
  /// details.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct PaymentMethodEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.billing.payment_method`: the
    /// family of the event types that carry it, and what tells the members of
    /// `WebhookEventObject` apart.
    ///
    /// It is always `organization.billing.payment_method`, the discriminator value naming this
    /// member of its union.
    public var object: String {
      "organization.billing.payment_method"
    }
    /// Identifier of the payment method, the payment provider's `pm_` identifier. It is
    /// not a UUID.
    public var id: String
    /// Identifier of the organization the payment method belongs to.
    public var organization_id: String
    /// Whether the organization is charged on it once this change was made.
    public var is_default: Bool

    /// Creates a `PaymentMethodEventObject` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      id: String,
      organization_id: String,
      is_default: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.organization_id = organization_id
      self.is_default = is_default
      configure(&self)
    }

    /// Reads a `PaymentMethodEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.is_default = try container.decode(Bool.self, forKey: "is_default")
    }

    /// Writes a `PaymentMethodEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.is_default, forKey: "is_default")
    }
  }
}
