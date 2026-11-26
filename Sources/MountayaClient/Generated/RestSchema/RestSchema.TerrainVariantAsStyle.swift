// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A terrain rendition as a complete map style document, referenced by URL and
  /// ready to hand to a map renderer unmodified. The URL is the Tile API's
  /// `getTerrainStyle`, and every address the style holds is the Tile API's as
  /// well, so a map draws the whole base map under the credential it sends there,
  /// and no URL carries a credential of Mountaya's.
  public struct TerrainVariantAsStyle: Sendable, Hashable, Codable {
    /// URL of the style document, ready to hand to a map renderer unmodified.
    /// Uncapped, unlike a URL a caller supplies: Mountaya issues this one, so
    /// there is no untrusted input for a ceiling to bound.
    public var url: URI

    /// Creates a `TerrainVariantAsStyle` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      url: URI,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.url = url
      configure(&self)
    }

    /// Reads a `TerrainVariantAsStyle` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.url = try container.decode(URI.self, forKey: "url")
    }

    /// Writes a `TerrainVariantAsStyle` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.url, forKey: "url")
    }
  }
}
