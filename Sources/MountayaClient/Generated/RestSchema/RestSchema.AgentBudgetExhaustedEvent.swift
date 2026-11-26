// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event reporting that a per-run budget was reached and the run will not
  /// continue. The terminal `done` event follows it with the `budget-exhausted`
  /// reason.
  public struct AgentBudgetExhaustedEvent: Sendable, Hashable, Codable {
    /// Always `budget-exhausted` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type an agent run's stream can send.
    ///
    /// It is always `budget-exhausted`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "budget-exhausted"
    }
    /// Which of the run's two budget ceilings was reached, its 24 provider turns
    /// or its $5.00 of estimated spend. It is the detail behind this event, not
    /// the run's terminal reason: that one is always `budget-exhausted` when
    /// this arrives.
    public var reason: RestSchema.AgentBudgetDimension

    /// Creates a `AgentBudgetExhaustedEvent` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      reason: RestSchema.AgentBudgetDimension,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.reason = reason
      configure(&self)
    }

    /// Reads a `AgentBudgetExhaustedEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.reason = try container.decode(RestSchema.AgentBudgetDimension.self, forKey: "reason")
    }

    /// Writes a `AgentBudgetExhaustedEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.reason, forKey: "reason")
    }
  }
}
