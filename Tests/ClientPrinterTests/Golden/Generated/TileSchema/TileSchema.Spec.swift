// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// The contract's `Spec`.
  public struct Spec: Sendable, Hashable, Codable {
    /// The contract's `url`.
    public var url: URI

    /// Creates a `Spec` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      url: URI,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.url = url
      configure(&self)
    }

    /// Reads a `Spec` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.url = try container.decode(URI.self, forKey: "url")
    }

    /// Writes a `Spec` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.url, forKey: "url")
    }
  }
}
