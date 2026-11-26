// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// How to open an organization's billing. Provisioning opens the billing
  /// account and no subscription, and charges nothing. The metered Data API
  /// subscription is opened by the first card the organization saves, unless the
  /// customer, or that card, still owes an invoice, which is the `402` and opens
  /// nothing, and is
  /// invoiced at the end of each billing period, a month counted from the day it
  /// opened, for the requests made in it, so there is
  /// no interval to choose and the one thing a caller decides here is the
  /// promotion code.
  public struct OrganizationBillingProvisionParams: Sendable, Hashable, Codable {
    /// A promotion code for the organization's first Data API subscription, as
    /// it was handed to the customer. It is checked against this organization,
    /// so a code restricted to another customer is refused with a `400`, and
    /// so is any code given to an organization that has already held a Data
    /// API subscription, which no code applies to. An accepted one is recorded,
    /// and applied when the first card opens the subscription. Omitted, none is
    /// recorded, and one recorded by an earlier call is cleared. Letters,
    /// digits, hyphens and underscores, at most 64, the form a code takes
    /// wherever it is read.
    public var promotion_code: String?

    /// Creates a `OrganizationBillingProvisionParams` from the properties the contract requires,
    /// the optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.promotion_code = nil
      configure(&self)
    }

    /// Reads a `OrganizationBillingProvisionParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.promotion_code = try container.decodeIfPresent(String.self, forKey: "promotion_code")
    }

    /// Writes a `OrganizationBillingProvisionParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.promotion_code, forKey: "promotion_code")
    }
  }
}
