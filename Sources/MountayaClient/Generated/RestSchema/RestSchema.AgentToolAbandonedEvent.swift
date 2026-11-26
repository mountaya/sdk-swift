// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event reporting that an outstanding call was given up on and the run
  /// moved on without its answer: a client tool whose result did not arrive, or a
  /// destructive server tool whose confirmation got no decision, each within two
  /// minutes. The caller clears any pending UI for the call. It is not terminal:
  /// the run continues with a synthesized failure in place of the missing answer.
  /// For a confirmation, the tool did not run, and a `tool-result` carrying that
  /// failure follows for the same tool call id.
  public struct AgentToolAbandonedEvent: Sendable, Hashable, Codable {
    /// Always `tool-abandoned` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type an agent run's stream can send.
    ///
    /// It is always `tool-abandoned`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "tool-abandoned"
    }
    /// The provider's tool-call id that was abandoned.
    public var tool_call_id: String
    /// Why this ONE tool call was given up on. It is a per-call vocabulary rather
    /// than a terminal one: the run carries on, and its own ending is reported by
    /// `AgentDoneEvent`.
    public var reason: RestSchema.AgentToolAbandonedReason?

    /// Creates a `AgentToolAbandonedEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      tool_call_id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.tool_call_id = tool_call_id
      self.reason = nil
      configure(&self)
    }

    /// Reads a `AgentToolAbandonedEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.tool_call_id = try container.decode(String.self, forKey: "tool_call_id")
      self.reason = try container.decodeIfPresent(
        RestSchema.AgentToolAbandonedReason.self, forKey: "reason")
    }

    /// Writes a `AgentToolAbandonedEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.tool_call_id, forKey: "tool_call_id")
      try container.encodeIfPresent(self.reason, forKey: "reason")
    }
  }
}
