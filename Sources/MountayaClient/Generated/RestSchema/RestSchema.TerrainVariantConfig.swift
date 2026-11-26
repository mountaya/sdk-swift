// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One rendition of a terrain, offered in both consumable forms. `style` is a
  /// complete map style document, for a client that renders the terrain as-is;
  /// `tiles` is the tile source alone, described by a TileJSON document, for a
  /// client composing its own style. The two describe the same map, so consume
  /// one, not both.
  public struct TerrainVariantConfig: Sendable, Hashable, Codable {
    /// This rendition as a complete map style document, for a client that renders
    /// the terrain as it is given.
    public var style: RestSchema.TerrainVariantAsStyle
    /// This rendition as a tile source alone, described by a TileJSON document,
    /// for a client composing a style of its own.
    public var tiles: RestSchema.TerrainVariantAsTiles

    /// Creates a `TerrainVariantConfig` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      style: RestSchema.TerrainVariantAsStyle,
      tiles: RestSchema.TerrainVariantAsTiles,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.style = style
      self.tiles = tiles
      configure(&self)
    }

    /// Reads a `TerrainVariantConfig` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.style = try container.decode(RestSchema.TerrainVariantAsStyle.self, forKey: "style")
      self.tiles = try container.decode(RestSchema.TerrainVariantAsTiles.self, forKey: "tiles")
    }

    /// Writes a `TerrainVariantConfig` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.style, forKey: "style")
      try container.encode(self.tiles, forKey: "tiles")
    }
  }
}
