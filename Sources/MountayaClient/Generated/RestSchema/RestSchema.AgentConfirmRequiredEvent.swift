// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event announcing that a destructive server tool is waiting for the
  /// caller's confirmation before it runs. The caller answers through the run's
  /// input endpoint with a `confirm` signal quoting the same tool call id, within
  /// two minutes. With no decision by then the tool does not run: the call is
  /// reported as `tool-abandoned` with the reason `timeout`, then as a failed
  /// `tool-result`, and a later `confirm` is accepted and ignored.
  public struct AgentConfirmRequiredEvent: Sendable, Hashable, Codable {
    /// Always `confirm-required` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type an agent run's stream can send.
    ///
    /// It is always `confirm-required`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "confirm-required"
    }
    /// The provider's tool-call id the confirmation decision answers.
    public var tool_call_id: String
    /// Name of the server tool awaiting confirmation.
    public var name: String
    /// Whether the stream already holds this confirmation's outcome. The server
    /// sets it on a replayed event only, one written from what the stream still
    /// holds before the live feed, when that replay also holds a `tool-result`
    /// or a `tool-abandoned` for the same tool call id. The caller does not ask
    /// about a settled confirmation again. One replayed without the marker is
    /// asked and answered as a live one, and that includes a confirmation the
    /// caller approved whose tool is still running, since the stream holds no
    /// outcome for it yet: a second `confirm` for that call is accepted and
    /// ignored, and the first decision stands. Omitted when false.
    public var settled: Bool?

    /// Creates a `AgentConfirmRequiredEvent` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      tool_call_id: String,
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.tool_call_id = tool_call_id
      self.name = name
      self.settled = nil
      configure(&self)
    }

    /// Reads a `AgentConfirmRequiredEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.tool_call_id = try container.decode(String.self, forKey: "tool_call_id")
      self.name = try container.decode(String.self, forKey: "name")
      self.settled = try container.decodeIfPresent(Bool.self, forKey: "settled")
    }

    /// Writes a `AgentConfirmRequiredEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.tool_call_id, forKey: "tool_call_id")
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.settled, forKey: "settled")
    }
  }
}
