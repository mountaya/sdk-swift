// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An organization's billing information as a webhook event carries it: whose it is, and
  /// which of its parts the change wrote. What invoices are addressed to is never carried:
  /// `getOrganizationBillingInfo` reads it.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct BillingInfoEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `organization.billing.info`: the family of the
    /// event types that carry it, and what tells the members of `WebhookEventObject`
    /// apart.
    ///
    /// It is always `organization.billing.info`, the discriminator value naming this member of its
    /// union.
    public var object: String {
      "organization.billing.info"
    }
    /// Identifier of the organization the billing information belongs to.
    public var organization_id: String
    /// The parts of the billing information the change wrote, each once. A part
    /// written with the value it already held is listed too.
    public var fields: [AdminSchema.BillingInfoField]

    /// Creates a `BillingInfoEventObject` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      organization_id: String,
      fields: [AdminSchema.BillingInfoField],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.organization_id = organization_id
      self.fields = fields
      configure(&self)
    }

    /// Reads a `BillingInfoEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.organization_id = try container.decode(String.self, forKey: "organization_id")
      self.fields = try container.decode([AdminSchema.BillingInfoField].self, forKey: "fields")
    }

    /// Writes a `BillingInfoEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.organization_id, forKey: "organization_id")
      try container.encode(self.fields, forKey: "fields")
    }
  }
}
