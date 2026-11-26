// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// Where an invoice stands. The order is the lifecycle: an invoice is drafted,
  /// opened for payment, and then ends paid or void, or is left uncollectible
  /// and still owed.
  ///
  /// These five are the payment provider's own set, echoed rather than translated.
  /// A client may switch on them, and should treat a value outside them as
  /// unrecognized rather than as an error: it would mean the provider had added a
  /// status, which is not something this contract gets to refuse on its behalf.
  ///
  /// `hosted_invoice_url` and `invoice_pdf` are absent while the status is `draft`
  /// and carry a link from `open` onwards (`hosted_invoice_url` never does for an
  /// organization billed by its agreement with Mountaya, or awaiting one), so a
  /// client that renders a pay button reads this field and offers the button only
  /// when `hosted_invoice_url` is present.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct InvoiceStatus: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// A draft, not finalized: it cannot be paid, and no link to pay it exists.
    public static let draft: Self = "draft"
    /// Finalized and payable. This is the status a payer is asked to act on.
    public static let `open`: Self = "open"
    /// Settled in full. Terminal.
    public static let paid: Self = "paid"
    /// Canceled before it was paid, and owed by nobody. Terminal. An organization's invoice history
    /// never lists one.
    public static let void: Self = "void"
    /// Finalized and unpaid after every retry, and still owed: the organization's card is charged
    /// for it before another Data API subscription opens, and the open is refused with a `402`
    /// while it stays unpaid. Paying it moves it to `paid`.
    public static let uncollectible: Self = "uncollectible"

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
