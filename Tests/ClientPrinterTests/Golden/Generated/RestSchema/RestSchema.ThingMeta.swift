// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// ThingMeta is an object the contract writes inline.
  public struct ThingMeta: Sendable, Hashable, Codable {
    /// The contract's `source`.
    public var source: String

    /// Creates a `ThingMeta` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      source: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.source = source
      configure(&self)
    }

    /// Reads a `ThingMeta` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.source = try container.decode(String.self, forKey: "source")
    }

    /// Writes a `ThingMeta` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.source, forKey: "source")
    }
  }
}
