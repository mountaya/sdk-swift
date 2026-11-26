// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A single-use secret for collecting a card in the caller's own page rather
  /// than sending the payer elsewhere. Hand `client_secret` to Stripe Elements, which
  /// confirms the card in the browser, then name the confirmed setup intent on
  /// `postOrganizationBillingPaymentMethod` to save the card against the
  /// organization.
  ///
  /// It prints every property but its secrets, each printed as `<redacted>`, however it is printed
  /// (`sdk/SPEC.md` §1).
  public struct SetupIntentSession: Sendable, Hashable, Codable, CustomDebugStringConvertible,
    CustomReflectable
  {
    /// The secret Stripe Elements confirms the card with. It is single-use and
    /// belongs to this organization alone.
    ///
    /// It is a secret: the type prints it as `<redacted>` wherever it is printed, in a log, a
    /// debugger's description or a dump, and a caller reads it as it is.
    public var client_secret: String

    /// Creates a `SetupIntentSession` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      client_secret: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.client_secret = client_secret
      configure(&self)
    }

    /// Reads a `SetupIntentSession` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.client_secret = try container.decode(String.self, forKey: "client_secret")
    }

    /// Writes a `SetupIntentSession` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.client_secret, forKey: "client_secret")
    }

    /// debugDescription is the value as a log may show it, which `print`, `String(describing:)` and
    /// `dump` all write: every property but its secrets, each printed as `<redacted>`.
    public var debugDescription: String {
      var fields: [String] = []
      fields.append("client_secret: <redacted>")
      return "SetupIntentSession(\(fields.joined(separator: ", ")))"
    }

    /// customMirror has no children, so `dump` and a debugger's variable view print the redacted
    /// description rather than the secrets.
    public var customMirror: Mirror {
      Mirror(self, children: [], displayStyle: .struct)
    }
  }
}
