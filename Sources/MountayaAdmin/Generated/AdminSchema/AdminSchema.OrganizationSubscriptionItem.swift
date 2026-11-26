// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// One line of a subscription: what is being billed, how much of it, and the
  /// usage dimension it reports against when it is metered. No line states how
  /// often it bills, because there is nothing to choose: the Data API line is
  /// metered and billed by the month.
  public struct OrganizationSubscriptionItem: Sendable, Hashable, Codable {
    /// Identifier of the price this line bills at.
    public var price_id: String
    /// How many units the line bills. On a metered line, which the Data API
    /// line is, it says nothing about what was used, which is read from the
    /// usage operations; a count of units billed as such is carried only by a
    /// line of a subscription Mountaya arranged separately.
    public var quantity: Int
    /// The usage dimension this line is metered on. Absent on a line billed by
    /// a count of units rather than by usage, which only a subscription
    /// Mountaya arranged separately carries.
    public var meter: AdminSchema.MeterDimension?

    /// Creates a `OrganizationSubscriptionItem` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      price_id: String,
      quantity: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.price_id = price_id
      self.quantity = quantity
      self.meter = nil
      configure(&self)
    }

    /// Reads a `OrganizationSubscriptionItem` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.price_id = try container.decode(String.self, forKey: "price_id")
      self.quantity = try container.decode(Int.self, forKey: "quantity")
      self.meter = try container.decodeIfPresent(AdminSchema.MeterDimension.self, forKey: "meter")
    }

    /// Writes a `OrganizationSubscriptionItem` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.price_id, forKey: "price_id")
      try container.encode(self.quantity, forKey: "quantity")
      try container.encodeIfPresent(self.meter, forKey: "meter")
    }
  }
}
