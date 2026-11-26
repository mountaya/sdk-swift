// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event carrying one incremental piece of streamed assistant text, a
  /// live preview of the turn's answer. Deltas are best-effort: one can be lost,
  /// they are never replayed, and a turn the server retries streams its text
  /// again, so they need not add up to the final text. The matching `message`
  /// event carries that text in full and is authoritative: a client that renders
  /// deltas live replaces them with it rather than rendering both.
  public struct AgentMessageDeltaEvent: Sendable, Hashable, Codable {
    /// Always `message-delta` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type an agent run's stream can send.
    ///
    /// It is always `message-delta`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "message-delta"
    }
    /// The next piece of assistant text.
    public var text: String

    /// Creates a `AgentMessageDeltaEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      text: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.text = text
      configure(&self)
    }

    /// Reads a `AgentMessageDeltaEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.text = try container.decode(String.self, forKey: "text")
    }

    /// Writes a `AgentMessageDeltaEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.text, forKey: "text")
    }
  }
}
