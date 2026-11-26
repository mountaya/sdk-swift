// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Asks the run to finish; the run ends successfully with a `done` terminal
  /// event.
  public struct AgentCloseInput: Sendable, Hashable, Codable {
    /// Always `close` on this input, and what the server routes the request body
    /// on. The enum carries every input an open run accepts.
    ///
    /// It is always `close`, the discriminator value naming this member of its union.
    public var type: RestSchema.AgentRunInputType {
      "close"
    }

    /// Creates a `AgentCloseInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      configure(&self)
    }

    /// Reads a `AgentCloseInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      _ = try decoder.container(keyedBy: WireKey.self)
    }

    /// Writes a `AgentCloseInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
    }
  }
}
