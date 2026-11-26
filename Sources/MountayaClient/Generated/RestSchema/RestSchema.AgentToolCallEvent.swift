// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event asking the browser to execute one client tool. The caller runs it
  /// and returns the outcome through the run's input endpoint as a `tool-result`
  /// signal correlated by the same tool call id, within two minutes. With no
  /// result by then the run gives the call up (`tool-abandoned`, reason
  /// `timeout`) and carries on, and a later `tool-result` is accepted and
  /// ignored.
  public struct AgentToolCallEvent: Sendable, Hashable, Codable {
    /// Always `tool-call` on this event, and the value of the record's `event:`
    /// field. Branch on it to route the event; the enum carries every type an
    /// agent run's stream can send.
    ///
    /// It is always `tool-call`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "tool-call"
    }
    /// The provider's tool-call id the result must quote back.
    public var tool_call_id: String
    /// Name of the client tool to execute.
    public var name: String
    /// Where this call runs, stated on the wire so a client branches on the field
    /// rather than inferring it from the event type. A client-side target is one
    /// the caller executes and answers with `postAgentRunInput`.
    public var target: RestSchema.AgentToolCallTarget
    /// The model's raw arguments for the call, forwarded verbatim. The caller
    /// re-validates them against the tool's own schema before acting.
    public var input: [String: JSONValue]?
    /// Whether the stream already holds this call's outcome. The server sets it
    /// on a replayed event only, one written from what the stream still holds
    /// before the live feed, when that replay also holds a `tool-result` or a
    /// `tool-abandoned` for the same tool call id. The caller neither runs a
    /// settled call nor answers it. A call replayed without the marker is still
    /// waiting: the caller runs it and answers it as it would a live one.
    /// Omitted when false.
    public var settled: Bool?

    /// Creates a `AgentToolCallEvent` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      tool_call_id: String,
      name: String,
      target: RestSchema.AgentToolCallTarget,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.tool_call_id = tool_call_id
      self.name = name
      self.target = target
      self.input = nil
      self.settled = nil
      configure(&self)
    }

    /// Reads a `AgentToolCallEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.tool_call_id = try container.decode(String.self, forKey: "tool_call_id")
      self.name = try container.decode(String.self, forKey: "name")
      self.target = try container.decode(RestSchema.AgentToolCallTarget.self, forKey: "target")
      self.input = try container.decodeIfPresent([String: JSONValue].self, forKey: "input")
      self.settled = try container.decodeIfPresent(Bool.self, forKey: "settled")
    }

    /// Writes a `AgentToolCallEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.tool_call_id, forKey: "tool_call_id")
      try container.encode(self.name, forKey: "name")
      try container.encode(self.target, forKey: "target")
      try container.encodeIfPresent(self.input, forKey: "input")
      try container.encodeIfPresent(self.settled, forKey: "settled")
    }
  }
}
