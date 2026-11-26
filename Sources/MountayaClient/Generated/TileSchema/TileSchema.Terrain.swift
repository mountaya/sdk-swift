// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// A built-in terrain: the base map itineraries and zones are drawn on, such as
  /// the summer topographic map or satellite imagery. `variants` carries its light
  /// and dark renditions, `locales` its display name per language.
  public struct Terrain: Sendable, Hashable, Codable {
    /// Identifier of the terrain. `slug` is the value a person reads; this is the
    /// one the catalog keys on.
    public var id: String
    /// The terrain's display name per language. Render from here rather than from
    /// `slug`: the slug is a stable identifier and is not translated.
    public var locales: TileSchema.Locales
    /// Stable, URL-safe identifier of the terrain. Unlike the display name in
    /// `locales`, it does not change between languages or releases. Lowercase
    /// letters, digits and single hyphens, the same shape every slug on this
    /// surface carries.
    public var slug: String
    /// The light and dark renditions of this terrain. Both are always present, so
    /// a client follows the user's color scheme without fetching the catalog
    /// again.
    public var variants: TileSchema.TerrainVariants

    /// Creates a `Terrain` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      id: String,
      locales: TileSchema.Locales,
      slug: String,
      variants: TileSchema.TerrainVariants,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.locales = locales
      self.slug = slug
      self.variants = variants
      configure(&self)
    }

    /// Reads a `Terrain` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.locales = try container.decode(TileSchema.Locales.self, forKey: "locales")
      self.slug = try container.decode(String.self, forKey: "slug")
      self.variants = try container.decode(TileSchema.TerrainVariants.self, forKey: "variants")
    }

    /// Writes a `Terrain` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.locales, forKey: "locales")
      try container.encode(self.slug, forKey: "slug")
      try container.encode(self.variants, forKey: "variants")
    }
  }
}
