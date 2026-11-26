// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// What a promotion code would be worth to this organization, so a client can
  /// show the discount before the code is given to provisioning, rather than
  /// finding out once the first card opens the subscription it discounts.
  ///
  /// When `valid` is false every other field is absent and nothing further is
  /// said: an unknown code, an expired one, and one restricted to a different
  /// customer are deliberately indistinguishable, so this operation cannot be
  /// used to discover which codes exist.
  public struct PromotionCodePreview: Sendable, Hashable, Codable {
    /// Whether the code can be applied by this organization. False for a code
    /// that is unknown, inactive, expired, or restricted to someone else, and
    /// the four are not told apart. It judges the code alone: a code discounts
    /// an organization's first Data API subscription only, so one that has
    /// already held a subscription is refused every code by
    /// `postOrganizationBillingProvision`, whatever this reads.
    public var valid: Bool
    /// How to name the discount to the payer. Present only when `valid` is
    /// true. Unbounded, unlike the labels a caller authors, because the text
    /// comes back from the payment provider and this contract does not get to
    /// set its ceiling.
    public var label: String?
    /// The discount as a percentage, so 20 is twenty percent off. Present only
    /// when `valid` is true and the discount is proportional, in which case
    /// `amount_off` is absent.
    public var percent_off: Double?
    /// The discount as a fixed sum, in the currency's minor unit. Present only
    /// when `valid` is true and the discount is a fixed sum, in which case
    /// `percent_off` is absent.
    public var amount_off: Int64?
    /// The ISO 4217 code `amount_off` is denominated in. Present only alongside
    /// `amount_off`.
    public var currency: String?
    /// How long the discount lasts: `once`, `repeating` or `forever`. Present
    /// only when `valid` is true. A word rather than a number, unlike the
    /// `duration` on a segment or a directions step, which is a count of
    /// seconds. The vocabulary is the payment provider's, so it is declared as
    /// a string rather than as an enum this contract would have to bump a tag
    /// to widen.
    public var duration: String?

    /// Creates a `PromotionCodePreview` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      valid: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.valid = valid
      self.label = nil
      self.percent_off = nil
      self.amount_off = nil
      self.currency = nil
      self.duration = nil
      configure(&self)
    }

    /// Reads a `PromotionCodePreview` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.valid = try container.decode(Bool.self, forKey: "valid")
      self.label = try container.decodeIfPresent(String.self, forKey: "label")
      self.percent_off = try container.decodeIfPresent(Double.self, forKey: "percent_off")
      self.amount_off = try container.decodeIfPresent(Int64.self, forKey: "amount_off")
      self.currency = try container.decodeIfPresent(String.self, forKey: "currency")
      self.duration = try container.decodeIfPresent(String.self, forKey: "duration")
    }

    /// Writes a `PromotionCodePreview` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.valid, forKey: "valid")
      try container.encodeIfPresent(self.label, forKey: "label")
      try container.encodeIfPresent(self.percent_off, forKey: "percent_off")
      try container.encodeIfPresent(self.amount_off, forKey: "amount_off")
      try container.encodeIfPresent(self.currency, forKey: "currency")
      try container.encodeIfPresent(self.duration, forKey: "duration")
    }
  }
}
