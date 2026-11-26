// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Input signal approving or rejecting a destructive server tool the run gated
  /// behind a confirmation.
  public struct AgentConfirmInput: Sendable, Hashable, Codable {
    /// Always `confirm` on this input, and what the server routes the request
    /// body on. The enum carries every input an open run accepts.
    ///
    /// It is always `confirm`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunInputType {
      "confirm"
    }
    /// The provider's tool-call id this decision applies to, as the
    /// `confirm-required` event carried it.
    public var tool_call_id: String
    /// Whether the caller approved the destructive tool. A false value cancels
    /// the tool and reports the rejection back to the model.
    public var approved: Bool

    /// Creates a `AgentConfirmInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      tool_call_id: String,
      approved: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.tool_call_id = tool_call_id
      self.approved = approved
      configure(&self)
    }

    /// Reads a `AgentConfirmInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.tool_call_id = try container.decode(String.self, forKey: "tool_call_id")
      self.approved = try container.decode(Bool.self, forKey: "approved")
    }

    /// Writes a `AgentConfirmInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.tool_call_id, forKey: "tool_call_id")
      try container.encode(self.approved, forKey: "approved")
    }
  }
}
