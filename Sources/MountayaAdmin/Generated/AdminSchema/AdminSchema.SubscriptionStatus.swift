// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Lifecycle state of a subscription. It is the value the organization's `data`
  /// capability follows, where the organization holds the Data API by its
  /// subscription. `canceled`, `unpaid`, `incomplete-expired` and `paused` suspend what
  /// the subscription grants, as does a subscription that reads `active` with its
  /// `paused` flag set, and a request that needed one of those capabilities
  /// answers `402` rather than failing silently. `active`, `trialing` and
  /// `incomplete` keep what it grants in force, and so does `past-due` once the
  /// subscription has paid an invoice. `past-due` is the window, at most 7 days,
  /// in which a failed renewal is retried before the subscription is canceled. A
  /// subscription that has never paid an invoice keeps nothing from its first
  /// failed payment. No operation in this contract opens a subscription that
  /// reads `trialing`, `incomplete` or `incomplete-expired`: the Data API
  /// subscription is opened by the organization's first card and reads `active`
  /// from that moment, or is not opened at all when that card is refused, or
  /// when the customer, or that card, still owes an invoice, which is the `402`
  /// and opens nothing, so those three are read only on a subscription Mountaya
  /// arranged separately. A status
  /// outside these eight, which the payment provider may add, is published in the
  /// same kebab-case and suspends what the subscription grants; treat it as
  /// unrecognized rather than as an error.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct SubscriptionStatus: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// In force. The Data API subscription opens in this status. It is metered from the first whole
    /// day, in UTC, after it opens, so the day it opens is not billed, and each billing period,
    /// which runs from the day of the month it opened to the same day of the next, is invoiced at
    /// that period's end.
    public static let active: Self = "active"
    /// On a trial, and in force for as long as it runs. No operation in this contract opens one, so
    /// it is read only on a subscription agreed separately.
    public static let trialing: Self = "trialing"
    /// A payment failed and the retry window, at most 7 days before cancellation, is still open.
    public static let pastDue: Self = "past-due"
    /// Canceled.
    public static let canceled: Self = "canceled"
    /// An invoice is still unpaid after every retry.
    public static let unpaid: Self = "unpaid"
    /// The first payment has not succeeded.
    public static let incomplete: Self = "incomplete"
    /// The first payment was not completed in time and the subscription expired.
    public static let incompleteExpired: Self = "incomplete-expired"
    /// Paused, and billing nothing for as long as it stays so.
    public static let paused: Self = "paused"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
