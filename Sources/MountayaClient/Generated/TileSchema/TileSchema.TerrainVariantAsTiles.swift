// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// A terrain rendition as a tile source alone, referenced by the URL of its
  /// TileJSON document, together with the tile size to declare when the source is
  /// added to a map. Declaring a different size offsets every zoom level.
  public struct TerrainVariantAsTiles: Sendable, Hashable, Codable {
    /// The tile size to declare when this source is added to a map. Only one
    /// value is served, and declaring a different one offsets every zoom level.
    public var size: TileSchema.TerrainTileSize
    /// URL of the TileJSON document describing this rendition's tiles: where
    /// they are fetched from, their zoom range and their attribution. It is the
    /// Tile API's `getTerrainTileJson`, whose tile template is the Tile API's
    /// `getTerrainTile`, so the tiles are drawn under the credential a map
    /// sends there, and no URL carries a credential of Mountaya's. It is a
    /// resolvable address rather than a tile template, so register it as the
    /// source's `url` rather than among its `tiles`, and hand it to the map
    /// renderer unmodified. Uncapped, unlike a URL a caller supplies: Mountaya
    /// issues this one, so there is no untrusted input for a ceiling to bound.
    public var url: URI

    /// Creates a `TerrainVariantAsTiles` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      size: TileSchema.TerrainTileSize,
      url: URI,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.size = size
      self.url = url
      configure(&self)
    }

    /// Reads a `TerrainVariantAsTiles` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.size = try container.decode(TileSchema.TerrainTileSize.self, forKey: "size")
      self.url = try container.decode(URI.self, forKey: "url")
    }

    /// Writes a `TerrainVariantAsTiles` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.size, forKey: "size")
      try container.encode(self.url, forKey: "url")
    }
  }
}
