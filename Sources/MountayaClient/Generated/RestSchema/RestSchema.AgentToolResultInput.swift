// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Input signal returning a browser-executed client tool's outcome to the run.
  /// The tool call id correlates it with the model's original tool call.
  public struct AgentToolResultInput: Sendable, Hashable, Codable {
    /// Always `tool-result` on this input, and what the server routes the request
    /// body on. The enum carries every input an open run accepts.
    ///
    /// It is always `tool-result`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunInputType {
      "tool-result"
    }
    /// The provider's tool-call id this result answers, as the `tool-call`
    /// event carried it.
    public var tool_call_id: String
    /// Whether the client tool succeeded.
    public var ok: Bool
    /// The client tool's structured result payload when ok is true, at most 64
    /// top-level fields and 64 KiB as sent.
    public var result: [String: JSONValue]?
    /// The client tool's failure message when ok is false, at most 2000
    /// characters.
    public var error: String?
    /// What the model should do about this specific failure of this specific
    /// tool, taken from the tool's playbook entry. It rides the failing result
    /// rather than the system prompt so it costs nothing for the failure codes
    /// that never fire, and arrives at the one moment it is actionable. Absent
    /// when the playbook has no entry for the tool and code pair. At most 2000
    /// characters.
    public var recovery: String?
    /// Machine-readable failure code the browser bus emits alongside error when
    /// ok is false. The run copies it onto the tool result so the model can
    /// branch on the kind of failure without parsing the human-readable message.
    /// Omitted on success.
    public var code: RestSchema.AgentToolErrorCode?

    /// Creates a `AgentToolResultInput` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      tool_call_id: String,
      ok: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.tool_call_id = tool_call_id
      self.ok = ok
      self.result = nil
      self.error = nil
      self.recovery = nil
      self.code = nil
      configure(&self)
    }

    /// Reads a `AgentToolResultInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.tool_call_id = try container.decode(String.self, forKey: "tool_call_id")
      self.ok = try container.decode(Bool.self, forKey: "ok")
      self.result = try container.decodeIfPresent([String: JSONValue].self, forKey: "result")
      self.error = try container.decodeIfPresent(String.self, forKey: "error")
      self.recovery = try container.decodeIfPresent(String.self, forKey: "recovery")
      self.code = try container.decodeIfPresent(RestSchema.AgentToolErrorCode.self, forKey: "code")
    }

    /// Writes a `AgentToolResultInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.tool_call_id, forKey: "tool_call_id")
      try container.encode(self.ok, forKey: "ok")
      try container.encodeIfPresent(self.result, forKey: "result")
      try container.encodeIfPresent(self.error, forKey: "error")
      try container.encodeIfPresent(self.recovery, forKey: "recovery")
      try container.encodeIfPresent(self.code, forKey: "code")
    }
  }
}
