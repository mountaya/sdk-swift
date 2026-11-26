// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The contract's `EventStarted`.
  public struct EventStarted: Sendable, Hashable, Codable {
    /// The contract's `type`.
    ///
    /// It is always `started`, the discriminator value naming this member of its union.
    public var type: RestSchema.EventType {
      "started"
    }
    /// The contract's `at`.
    public var at: Date

    /// Creates a `EventStarted` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      at: Date,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.at = at
      configure(&self)
    }

    /// Reads a `EventStarted` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.at = try container.decodeWired(Date.self, forKey: "at")
    }

    /// Writes a `EventStarted` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encodeWired(self.at, forKey: "at")
    }
  }
}
