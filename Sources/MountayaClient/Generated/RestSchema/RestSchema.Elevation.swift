// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The elevation raster a map bakes its relief from: a `raster-dem` source whose
  /// pixels encode height rather than colour.
  ///
  /// It is not a layer a caller turns on. Nothing draws it, and a map that adds it
  /// as an ordinary source shows a garish false-colour image. It is consumed as the
  /// terrain source a renderer reads heights out of, which is what turns a flat base
  /// map into a three-dimensional one and what a hillshade or a slope reading is
  /// computed against.
  ///
  /// Served through a TileJSON document rather than a tile template, because a
  /// renderer needs the encoding, bounds and zoom range before it can decode a
  /// single pixel.
  public struct Elevation: Sendable, Hashable, Codable {
    /// Identifier of the elevation raster. It belongs to no terrain, so it has an
    /// identifier of its own, which stays the same across releases.
    public var id: String
    /// The tile size to declare when this source is added to a map. Only one
    /// value is served, and declaring a different one offsets every zoom level.
    public var tile_size: RestSchema.ElevationTileSize
    /// URL of the TileJSON document describing the elevation source, ready to
    /// hand to a map renderer unmodified. It is the Tile API's
    /// `getElevationTileJson`, whose tile template is the Tile API's
    /// `getElevationTile`, so the heights are drawn under the credential a map
    /// sends there, and no URL carries a credential of Mountaya's. Uncapped,
    /// unlike a URL a caller supplies: Mountaya issues this one, so there is no
    /// untrusted input for a ceiling to bound.
    public var url: URI

    /// Creates a `Elevation` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      id: String,
      tile_size: RestSchema.ElevationTileSize,
      url: URI,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.tile_size = tile_size
      self.url = url
      configure(&self)
    }

    /// Reads a `Elevation` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.tile_size = try container.decode(RestSchema.ElevationTileSize.self, forKey: "tile_size")
      self.url = try container.decode(URI.self, forKey: "url")
    }

    /// Writes a `Elevation` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encode(self.tile_size, forKey: "tile_size")
      try container.encode(self.url, forKey: "url")
    }
  }
}
