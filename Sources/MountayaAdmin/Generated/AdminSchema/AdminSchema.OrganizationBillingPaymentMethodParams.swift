// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The setup intent to save a card from, after Stripe Elements has confirmed it
  /// in the browser. It is checked against the organization before anything is
  /// saved: one that is unknown or belongs to another organization is a `404`,
  /// the two answered alike, and one of this organization that has not been
  /// confirmed, or that carries no payment method, is a `409` naming
  /// `setup_intent_id`. One that is still processing, as a SEPA Direct Debit
  /// mandate is for a while, is accepted.
  public struct OrganizationBillingPaymentMethodParams: Sendable, Hashable, Codable {
    /// Identifier of the confirmed setup intent, as returned by
    /// `postOrganizationBillingPaymentMethodSetup` and confirmed by Stripe
    /// Elements: `seti_` and at most 250 more letters, digits and underscores.
    public var setup_intent_id: String

    /// Creates a `OrganizationBillingPaymentMethodParams` from the properties the contract
    /// requires, the optional ones being set in `configure`.
    public init(
      setup_intent_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.setup_intent_id = setup_intent_id
      configure(&self)
    }

    /// Reads a `OrganizationBillingPaymentMethodParams` from the JSON object the contract
    /// describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.setup_intent_id = try container.decode(String.self, forKey: "setup_intent_id")
    }

    /// Writes a `OrganizationBillingPaymentMethodParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.setup_intent_id, forKey: "setup_intent_id")
    }
  }
}
