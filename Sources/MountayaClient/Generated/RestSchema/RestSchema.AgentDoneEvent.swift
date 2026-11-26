// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event terminating a run that has finished, carrying how it ended. It is
  /// the last frame on the stream and the signal to close the connection.
  ///
  /// A run that fails publishes an `error` event first, naming what went wrong,
  /// and then this one with the reason `failed`.
  public struct AgentDoneEvent: Sendable, Hashable, Codable {
    /// Always `done` on this event, and the value of the record's `event:` field.
    /// Branch on it to route the event; the enum carries every type an agent
    /// run's stream can send.
    ///
    /// It is always `done`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "done"
    }
    /// How the run ended. Every run that ends on its own emits this event, so
    /// this field is what tells a run that finished its work from one that was
    /// cut short. A run stopped from outside, which is what becomes of one still
    /// going after 24 hours, emits none: its stream, reopened, closes once it
    /// has replayed what it holds.
    public var reason: RestSchema.AgentRunReason

    /// Creates a `AgentDoneEvent` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      reason: RestSchema.AgentRunReason,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.reason = reason
      configure(&self)
    }

    /// Reads a `AgentDoneEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.reason = try container.decode(RestSchema.AgentRunReason.self, forKey: "reason")
    }

    /// Writes a `AgentDoneEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.reason, forKey: "reason")
    }
  }
}
