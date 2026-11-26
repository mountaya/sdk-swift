// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The light and dark renditions of a terrain. Both are always present, so a
  /// client can follow the user's color scheme without refetching the catalog.
  public struct TerrainVariants: Sendable, Hashable, Codable {
    /// The rendition to draw under a dark color scheme.
    public var dark: RestSchema.TerrainVariantConfig
    /// The rendition to draw under a light color scheme.
    public var light: RestSchema.TerrainVariantConfig

    /// Creates a `TerrainVariants` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      dark: RestSchema.TerrainVariantConfig,
      light: RestSchema.TerrainVariantConfig,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.dark = dark
      self.light = light
      configure(&self)
    }

    /// Reads a `TerrainVariants` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.dark = try container.decode(RestSchema.TerrainVariantConfig.self, forKey: "dark")
      self.light = try container.decode(RestSchema.TerrainVariantConfig.self, forKey: "light")
    }

    /// Writes a `TerrainVariants` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.dark, forKey: "dark")
      try container.encode(self.light, forKey: "light")
    }
  }
}
