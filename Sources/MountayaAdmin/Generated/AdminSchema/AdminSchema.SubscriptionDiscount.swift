// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The discount on a subscription. It is read from the subscription itself rather
  /// than remembered from the moment the code was given, so a client shows the
  /// active discount on every visit and not only on the one where the code was
  /// entered. It says how long the discount lasts and, when it stops, when, so a
  /// client never presents a discount that is about to lapse as a lasting one.
  /// Absent from a subscription carrying no discount.
  public struct SubscriptionDiscount: Sendable, Hashable, Codable {
    /// How long the discount lasts: `once`, `repeating` or `forever`, the same
    /// vocabulary the promotion-code preview answers, so a client describes
    /// the running discount the way it described the code. A word rather than
    /// a number, unlike the `duration` on a segment or a directions step,
    /// which is a count of seconds. The vocabulary is the payment provider's,
    /// so it is declared as a string rather than as an enum this contract
    /// would have to bump a tag to widen.
    public var duration: String
    /// When the discount stops applying, for a `repeating` discount: invoices
    /// issued after it carry no discount. Null for a `forever` discount, which
    /// never ends, and for a `once` discount, which applies to a single
    /// invoice and has no date of its own.
    public var ends_at: Date?
    /// How to name the discount to the payer, never empty: the discount's own
    /// name, else the promotion code it was applied with, else, for an unnamed
    /// discount applied without a code, the discount's identifier at the
    /// payment provider.
    public var label: String
    /// The discount as a percentage, so 20 is twenty percent off. Present only
    /// when the discount is proportional, in which case `amount_off` is absent.
    public var percent_off: Double?
    /// The discount as a fixed sum, in the currency's minor unit. Present only
    /// when the discount is a fixed sum, in which case `percent_off` is absent.
    public var amount_off: Int64?
    /// The ISO 4217 code `amount_off` is denominated in. Present only alongside
    /// `amount_off`.
    public var currency: String?

    /// Creates a `SubscriptionDiscount` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      duration: String,
      ends_at: Date?,
      label: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.duration = duration
      self.ends_at = ends_at
      self.label = label
      self.percent_off = nil
      self.amount_off = nil
      self.currency = nil
      configure(&self)
    }

    /// Reads a `SubscriptionDiscount` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.duration = try container.decode(String.self, forKey: "duration")
      self.ends_at = try container.decodeWiredIfPresent(Date.self, forKey: "ends_at")
      self.label = try container.decode(String.self, forKey: "label")
      self.percent_off = try container.decodeIfPresent(Double.self, forKey: "percent_off")
      self.amount_off = try container.decodeIfPresent(Int64.self, forKey: "amount_off")
      self.currency = try container.decodeIfPresent(String.self, forKey: "currency")
    }

    /// Writes a `SubscriptionDiscount` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.duration, forKey: "duration")
      try container.encodeWiredNullable(self.ends_at, forKey: "ends_at")
      try container.encode(self.label, forKey: "label")
      try container.encodeIfPresent(self.percent_off, forKey: "percent_off")
      try container.encodeIfPresent(self.amount_off, forKey: "amount_off")
      try container.encodeIfPresent(self.currency, forKey: "currency")
    }
  }
}
