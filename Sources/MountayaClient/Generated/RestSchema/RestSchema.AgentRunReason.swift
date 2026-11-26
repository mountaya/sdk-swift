// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Machine-readable terminal reason recorded on a run's result, describing how
  /// the run ended.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct AgentRunReason: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// The conversation went quiet, no user message arriving within 30 minutes of the run's last
    /// answer, and the run completed.
    public static let completed: Self = "completed"
    /// The caller asked the run to finish and it ended successfully.
    public static let closed: Self = "closed"
    /// A provider error, or an error in another step of the run, survived its retries and failed
    /// the run.
    public static let failed: Self = "failed"
    /// A per-run ceiling, 24 provider turns or $5.00 of estimated spend, was reached and the run
    /// stopped.
    public static let budgetExhausted: Self = "budget-exhausted"
    /// The provider was rate limited (429) and the run stopped. The run is over; after a short wait
    /// start a new run.
    public static let rateLimited: Self = "rate-limited"
    /// The model repeated the same tool call with the same arguments after being told to change
    /// approach, so the run stopped rather than burning its budget on a loop.
    public static let looping: Self = "looping"

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
