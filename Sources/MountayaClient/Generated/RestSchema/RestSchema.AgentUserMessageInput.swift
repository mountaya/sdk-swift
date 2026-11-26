// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Input signal delivering a follow-up user message into a running conversation.
  public struct AgentUserMessageInput: Sendable, Hashable, Codable {
    /// Always `user-message` on this input, and what the server routes the
    /// request body on. The enum carries every input an open run accepts.
    ///
    /// It is always `user-message`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunInputType {
      "user-message"
    }
    /// The user's message text. Bounded exactly like the message that opens a
    /// run: trimmed before validation, and capped because a signal payload joins
    /// the transcript the run replays on every continuation.
    public var content: String

    /// Creates a `AgentUserMessageInput` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      content: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.content = content
      configure(&self)
    }

    /// Reads a `AgentUserMessageInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.content = try container.decode(String.self, forKey: "content")
    }

    /// Writes a `AgentUserMessageInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.content, forKey: "content")
    }
  }
}
