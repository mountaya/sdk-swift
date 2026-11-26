// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One entry in the billing catalog. There is one product per unit of access an
  /// organization can buy, and each carries the capabilities it grants, how it is
  /// quantified, and the price it is sold on. The Data API is the one
  /// product sold this way. What an agreement with Mountaya grants is not in the
  /// catalog.
  public struct BillingProduct: Sendable, Hashable, Codable {
    /// Stable identifier of the product. It is what a client keys on; the label
    /// beside it is what a client shows.
    public var key: String
    /// The product's name, as it reads to a buyer. Unbounded, unlike the labels
    /// a caller authors on a waypoint or an AI credential field, because a
    /// caller never writes it.
    public var label: String
    /// The capabilities the organization holds once this product is bought.
    public var granted_capabilities: [AdminSchema.Capability]
    /// How the product is counted.
    public var unit_kind: AdminSchema.BillingUnitKind
    /// Whether the product is agreed rather than bought: it is granted by the
    /// organization's agreement with Mountaya, and no card opens it.
    public var contact_sales_only: Bool
    /// The prices the product is sold on, one entry each. The Data API is sold
    /// on one metered price, billed by the month. A price whose display figure
    /// could not be resolved is left out rather than sent empty, so a product
    /// where none resolved carries an empty list and a reader shows it without
    /// an amount rather than failing the whole catalog.
    public var prices: [AdminSchema.BillingPricing]

    /// Creates a `BillingProduct` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      key: String,
      label: String,
      granted_capabilities: [AdminSchema.Capability],
      unit_kind: AdminSchema.BillingUnitKind,
      contact_sales_only: Bool,
      prices: [AdminSchema.BillingPricing],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.key = key
      self.label = label
      self.granted_capabilities = granted_capabilities
      self.unit_kind = unit_kind
      self.contact_sales_only = contact_sales_only
      self.prices = prices
      configure(&self)
    }

    /// Reads a `BillingProduct` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.key = try container.decode(String.self, forKey: "key")
      self.label = try container.decode(String.self, forKey: "label")
      self.granted_capabilities = try container.decode(
        [AdminSchema.Capability].self, forKey: "granted_capabilities")
      self.unit_kind = try container.decode(AdminSchema.BillingUnitKind.self, forKey: "unit_kind")
      self.contact_sales_only = try container.decode(Bool.self, forKey: "contact_sales_only")
      self.prices = try container.decode([AdminSchema.BillingPricing].self, forKey: "prices")
    }

    /// Writes a `BillingProduct` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.key, forKey: "key")
      try container.encode(self.label, forKey: "label")
      try container.encode(self.granted_capabilities, forKey: "granted_capabilities")
      try container.encode(self.unit_kind, forKey: "unit_kind")
      try container.encode(self.contact_sales_only, forKey: "contact_sales_only")
      try container.encode(self.prices, forKey: "prices")
    }
  }
}
