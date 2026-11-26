// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event carrying the outcome of a tool call, server- or client-side, for
  /// display. It mirrors back what the run recorded, so a caller that executed the
  /// tool itself sees the same settled outcome the model did.
  public struct AgentToolResultEvent: Sendable, Hashable, Codable {
    /// Always `tool-result` on this event, and the value of the record's `event:`
    /// field. Branch on it to route the event; the enum carries every type an
    /// agent run's stream can send.
    ///
    /// It is always `tool-result`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "tool-result"
    }
    /// The provider's tool-call id this outcome belongs to.
    public var tool_call_id: String
    /// Whether the tool call succeeded. When false, the failure is in `error`
    /// and the run carries on rather than ending.
    public var ok: Bool
    /// Short human-readable line describing what the tool did, for the chat
    /// transcript. Omitted when the tool has nothing worth saying.
    public var summary: String?
    /// The tool's structured result payload when ok is true.
    public var data: [String: JSONValue]?
    /// The tool's failure message when ok is false.
    public var error: String?

    /// Creates a `AgentToolResultEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      tool_call_id: String,
      ok: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.tool_call_id = tool_call_id
      self.ok = ok
      self.summary = nil
      self.data = nil
      self.error = nil
      configure(&self)
    }

    /// Reads a `AgentToolResultEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.tool_call_id = try container.decode(String.self, forKey: "tool_call_id")
      self.ok = try container.decode(Bool.self, forKey: "ok")
      self.summary = try container.decodeIfPresent(String.self, forKey: "summary")
      self.data = try container.decodeIfPresent([String: JSONValue].self, forKey: "data")
      self.error = try container.decodeIfPresent(String.self, forKey: "error")
    }

    /// Writes a `AgentToolResultEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.tool_call_id, forKey: "tool_call_id")
      try container.encode(self.ok, forKey: "ok")
      try container.encodeIfPresent(self.summary, forKey: "summary")
      try container.encodeIfPresent(self.data, forKey: "data")
      try container.encodeIfPresent(self.error, forKey: "error")
    }
  }
}
