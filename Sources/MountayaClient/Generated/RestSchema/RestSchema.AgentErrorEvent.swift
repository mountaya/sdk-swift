// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event carrying a turn-level error surfaced to the caller. The message
  /// is safe for display and carries no internal detail.
  ///
  /// It is published only as the run ends: the terminal `done` follows it, with
  /// the reason `rate-limited`, `looping` or `failed`. A client shows the message
  /// and reads how the run ended from that `done`.
  public struct AgentErrorEvent: Sendable, Hashable, Codable {
    /// Always `error` on this event, and the value of the record's `event:`
    /// field. Branch on it to route the event; the enum carries every type an
    /// agent run's stream can send.
    ///
    /// It is always `error`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "error"
    }
    /// Display-safe description of what went wrong.
    ///
    /// Unbounded, and not the same kind of value as the 1..4000 `message` a
    /// caller sends to open a run: that one is a prompt this bounds before it
    /// is paid for, this one is a fault report written by the server. Render it
    /// and branch on `code`.
    public var message: String
    /// Machine-readable error tag the caller branches on. Always present: an
    /// error with no more specific tag carries `run-failed`.
    public var code: RestSchema.AgentErrorCode

    /// Creates a `AgentErrorEvent` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      message: String,
      code: RestSchema.AgentErrorCode,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.message = message
      self.code = code
      configure(&self)
    }

    /// Reads a `AgentErrorEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.message = try container.decode(String.self, forKey: "message")
      self.code = try container.decode(RestSchema.AgentErrorCode.self, forKey: "code")
    }

    /// Writes a `AgentErrorEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.message, forKey: "message")
      try container.encode(self.code, forKey: "code")
    }
  }
}
