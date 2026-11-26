// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A payment method saved against the organization's billing account. `type`
  /// says which instrument it is and which sub-object is present: `card` carries
  /// `card`, and `sepa_debit` carries `sepa_debit`. `is_default` marks the one
  /// invoices and subscriptions charge; at most one saved method carries it, and
  /// none does until a default has been chosen.
  public struct PaymentMethod: Sendable, Hashable, Codable {
    /// Identifier of the payment method. It is what names the method when
    /// making it the default or detaching it. Opaque, and issued by the payment
    /// provider rather than by Mountaya, so do not parse it as a UUID the way
    /// every `id` Mountaya issues can be. It is the same `pm_` identifier the
    /// `payment_method_id` path parameter takes.
    public var id: String
    /// Which instrument the method is, in the payment provider's own words, and
    /// so an open set rather than an enum: `card` and `sepa_debit` are the two
    /// that carry a sub-object below. A method of any other kind is listed too,
    /// with neither sub-object, so a client that can only show those two reads
    /// this to skip the rest rather than failing on it.
    public var type: String
    /// Whether this is the method invoices and subscriptions charge.
    public var is_default: Bool
    /// The card's display details. Present only when `type` is `card`.
    public var card: AdminSchema.PaymentMethodCard?
    /// The mandate's display details. Present only when `type` is
    /// `sepa_debit`.
    public var sepa_debit: AdminSchema.PaymentMethodSepaDebit?

    /// Creates a `PaymentMethod` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      id: String,
      type: String,
      is_default: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.type = type
      self.is_default = is_default
      self.card = nil
      self.sepa_debit = nil
      configure(&self)
    }

    /// Reads a `PaymentMethod` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.type = try container.decode(String.self, forKey: "type")
      self.is_default = try container.decode(Bool.self, forKey: "is_default")
      self.card = try container.decodeIfPresent(AdminSchema.PaymentMethodCard.self, forKey: "card")
      self.sepa_debit = try container.decodeIfPresent(
        AdminSchema.PaymentMethodSepaDebit.self, forKey: "sepa_debit")
    }

    /// Writes a `PaymentMethod` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.type, forKey: "type")
      try container.encode(self.is_default, forKey: "is_default")
      try container.encodeIfPresent(self.card, forKey: "card")
      try container.encodeIfPresent(self.sepa_debit, forKey: "sepa_debit")
    }
  }
}
