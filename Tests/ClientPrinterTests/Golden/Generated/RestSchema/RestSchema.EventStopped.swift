// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The contract's `EventStopped`.
  public struct EventStopped: Sendable, Hashable, Codable {
    /// The contract's `type`.
    ///
    /// It is always `stopped`, the discriminator value naming this member of its union.
    public var type: RestSchema.EventType {
      "stopped"
    }
    /// The contract's `reason`.
    public var reason: String?

    /// Creates a `EventStopped` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.reason = nil
      configure(&self)
    }

    /// Reads a `EventStopped` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.reason = try container.decodeIfPresent(String.self, forKey: "reason")
    }

    /// Writes a `EventStopped` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.type, forKey: "type")
      try container.encodeIfPresent(self.reason, forKey: "reason")
    }
  }
}
