// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Discriminator for the kind of event published on an agent run's event stream.
  /// It is the `event:` field of each Server-Sent Events frame.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct AgentRunEventType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// One incremental piece of streamed assistant text.
    public static let messageDelta: Self = "message-delta"
    /// A complete assistant message.
    public static let message: Self = "message"
    /// A client tool the browser must execute, with its tool call id, name, and raw arguments.
    public static let toolCall: Self = "tool-call"
    /// The outcome of a tool (server- or client-side), for display.
    public static let toolResult: Self = "tool-result"
    /// A destructive server tool is waiting for the caller's confirmation before it runs.
    public static let confirmRequired: Self = "confirm-required"
    /// A call's answer never arrived within two minutes, a client tool's result or the decision on
    /// a destructive tool's confirmation, and the run moved on.
    public static let toolAbandoned: Self = "tool-abandoned"
    /// The run answered while success criteria its retrieved skills promised are not backed by the
    /// workspace. Informational and never terminal.
    public static let checksUnmet: Self = "checks-unmet"
    /// The run finished a turn and awaits the next user message.
    public static let awaitingInput: Self = "awaiting-input"
    /// A per-run ceiling, 24 provider turns or $5.00 of estimated spend, was reached and the run
    /// will not continue.
    public static let budgetExhausted: Self = "budget-exhausted"
    /// A turn-level error surfaced to the caller.
    public static let error: Self = "error"
    /// The terminal event for a run that has finished, carrying how it ended.
    public static let done: Self = "done"
    /// The credential the stream was opened with ended, so the stream closes while the run goes on;
    /// reopen it with a fresh session token and `Last-Event-ID`.
    public static let reconnect: Self = "reconnect"

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
