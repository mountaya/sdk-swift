// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What one price on a catalog product costs, for display. The catalog sells
  /// one product, the Data API, on one metered monthly price: it is priced on
  /// what is used, so it carries no flat amount and reads `unit_amount: null`
  /// with `metered: true`. A price that is not metered would carry its flat
  /// figure in `unit_amount` instead.
  public struct BillingPricing: Sendable, Hashable, Codable {
    /// The flat per-unit amount, in the currency's minor unit, so 15000 in EUR
    /// is 150.00 euros. Null for a metered price, which has no flat amount to
    /// show.
    public var unit_amount: Int?
    /// The lowercase ISO 4217 code the price bills in, for example `eur`.
    public var currency: String
    /// How often the price recurs: `month` for the one price the catalog
    /// sells.
    public var interval: AdminSchema.BillingInterval
    /// Whether the price is billed on usage. A metered price has no
    /// `unit_amount`, so a reader shows it as metered rather than as a figure.
    public var metered: Bool

    /// Creates a `BillingPricing` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      unit_amount: Int?,
      currency: String,
      interval: AdminSchema.BillingInterval,
      metered: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.unit_amount = unit_amount
      self.currency = currency
      self.interval = interval
      self.metered = metered
      configure(&self)
    }

    /// Reads a `BillingPricing` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.unit_amount = try container.decodeIfPresent(Int.self, forKey: "unit_amount")
      self.currency = try container.decode(String.self, forKey: "currency")
      self.interval = try container.decode(AdminSchema.BillingInterval.self, forKey: "interval")
      self.metered = try container.decode(Bool.self, forKey: "metered")
    }

    /// Writes a `BillingPricing` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeNullable(self.unit_amount, forKey: "unit_amount")
      try container.encode(self.currency, forKey: "currency")
      try container.encode(self.interval, forKey: "interval")
      try container.encode(self.metered, forKey: "metered")
    }
  }
}
