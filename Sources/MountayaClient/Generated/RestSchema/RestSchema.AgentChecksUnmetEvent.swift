// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Stream event reporting that the run answered while success criteria its
  /// retrieved skills promised are not backed by the workspace. It is informational
  /// and never terminal: the answer stands, and the user decides what to do with
  /// it.
  public struct AgentChecksUnmetEvent: Sendable, Hashable, Codable {
    /// Always `checks-unmet` on this event, and the value of the record's
    /// `event:` field. Branch on it to route the event; the enum carries every
    /// type an agent run's stream can send.
    ///
    /// It is always `checks-unmet`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunEventType {
      "checks-unmet"
    }
    /// The authored description of each criterion that did not hold, phrased for
    /// the person reading the answer rather than as an internal state name.
    public var unmet: [String]

    /// Creates a `AgentChecksUnmetEvent` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      unmet: [String],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.unmet = unmet
      configure(&self)
    }

    /// Reads a `AgentChecksUnmetEvent` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.unmet = try container.decode([String].self, forKey: "unmet")
    }

    /// Writes a `AgentChecksUnmetEvent` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encode(self.unmet, forKey: "unmet")
    }
  }
}
