// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Machine-readable tag on an agent run's error event, naming what went wrong so
  /// a caller can branch on it rather than on display text.
  ///
  /// It is a per-error vocabulary, not the run's terminal reason: a run whose error
  /// code is `ai-provider-not-configured` ends with the `failed` terminal reason.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct AgentErrorCode: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The provider rate limited the run (429). The run is over; after a short wait start a new
    /// run.
    public static let rateLimited: Self = "rate-limited"
    /// The organization has no AI provider credential configured, so no turn can run.
    public static let aiProviderNotConfigured: Self = "ai-provider-not-configured"
    /// A provider call failed with a message safe to show; the run stopped.
    public static let providerFailed: Self = "provider-failed"
    /// A fault other than a provider call ended the run; the message is a fixed generic line
    /// carrying no internal detail.
    public static let runFailed: Self = "run-failed"
    /// The model repeated the same tool call with the same arguments after being told to change
    /// approach, so the run stopped rather than spending its budget on a loop.
    public static let looping: Self = "looping"
    /// The member who started the run holds no write role in the organization it acts in, or that
    /// organization does not hold Map Studio, so the run stopped before its next turn.
    public static let accessRevoked: Self = "access-revoked"

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
