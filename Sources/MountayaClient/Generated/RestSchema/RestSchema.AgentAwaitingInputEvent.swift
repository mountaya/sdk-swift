// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event reporting that the run finished a turn and awaits the next user
  /// message. The stream stays open: a follow-up message sent to the run's input
  /// endpoint resumes the same conversation rather than starting a new run. The
  /// run waits 30 minutes for it; with no message by then it completes, sending
  /// `done` with the reason `completed`, and a later `user-message` is refused
  /// with 409.
  public struct AgentAwaitingInputEvent: Sendable, Hashable, Codable {
    /// Always `awaiting-input` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type an agent run's stream can send.
    ///
    /// It is always `awaiting-input`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "awaiting-input"
    }

    /// Creates a `AgentAwaitingInputEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      configure(&self)
    }

    /// Reads a `AgentAwaitingInputEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      _ = try decoder.container(keyedBy: WireKey.self)
    }

    /// Writes a `AgentAwaitingInputEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
    }
  }
}
