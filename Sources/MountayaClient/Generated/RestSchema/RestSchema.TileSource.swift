// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A single map source to register with `map.addSource()`. Bundles the
  /// `{z}/{x}/{y}` tile URL template, the source kind, its zoom bounds, and the
  /// render-layers that draw from it.
  public struct TileSource: Sendable, Hashable, Codable {
    /// Attribution HTML to display on the map for this source: the credit of
    /// whoever supplies its data, Mountaya for a resource source and the data
    /// provider for an overlay. Pass through to the `attribution` option of
    /// `map.addSource()`.
    public var attribution: String?
    /// Unique source identifier. Use it as the first argument to
    /// `map.addSource()` and as the `source` of every layer that draws from it.
    ///
    /// Declared as a string rather than a UUID so that it stays opaque: a
    /// resource source is named by the resource's id, and an overlay or
    /// aggregate source by a fixed identifier of its own. Every one of them is
    /// spelled as a UUID, but that shape is not part of this contract, so treat
    /// it as an opaque string and match it against a layer's `source` rather
    /// than parsing it.
    public var id: String
    /// Render-layers to draw from this source, in paint order. Each becomes one
    /// `map.addLayer()` call.
    public var layers: [RestSchema.TileLayer]
    /// Edge length in pixels of one raster tile, for `map.addSource()`'s
    /// `tileSize`. Omitted for vector sources, which have no pixel size of their
    /// own.
    public var size: RestSchema.TileSourceSize?
    /// Tile URL templates with `{z}`, `{x}`, and `{y}` placeholders that the map
    /// library expands per tile. Usually a single entry pointing at the matching
    /// `{z}/{x}/{y}` endpoint. Hand the template to the map library with its
    /// placeholders intact: the library substitutes them as it pans and zooms, so
    /// a template expanded before it is handed over produces one tile rather
    /// than a map. An overlay's template, and in a layer catalog the itinerary
    /// and zone layers' templates, carry the `organization_id` the
    /// specification or the catalog was asked for with, when one was sent, as a
    /// query string of its own, so a credential added to such a template joins
    /// it with `&` rather than starting a second `?`.
    public var tiles: [String]
    /// What kind of data the source serves, which decides how a map library reads
    /// its tiles. A `raster-dem` source carries elevation rather than pixels, so
    /// it feeds terrain and hillshade rather than being drawn directly.
    public var type: RestSchema.TileSourceType
    /// Deepest zoom a map library requests this source's tiles at. A layer drawn
    /// from the source can reach deeper, and a map overzooms the source's tiles
    /// for it. It says where to ask rather than what is refused: a tile asked for
    /// deeper is still served, and on a specification served to a publishable
    /// key the value is brought within the organization's zoom bounds.
    public var zoom_max: Int
    /// Shallowest zoom a map library requests this source's tiles at. Like
    /// `zoom_max`, it says where to ask rather than what is refused, and on a
    /// specification served to a publishable key it is brought within the
    /// organization's zoom bounds.
    public var zoom_min: Int

    /// Creates a `TileSource` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      id: String,
      layers: [RestSchema.TileLayer],
      tiles: [String],
      type: RestSchema.TileSourceType,
      zoom_max: Int,
      zoom_min: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.attribution = nil
      self.id = id
      self.layers = layers
      self.size = nil
      self.tiles = tiles
      self.type = type
      self.zoom_max = zoom_max
      self.zoom_min = zoom_min
      configure(&self)
    }

    /// Reads a `TileSource` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.attribution = try container.decodeIfPresent(String.self, forKey: "attribution")
      self.id = try container.decode(String.self, forKey: "id")
      self.layers = try container.decode([RestSchema.TileLayer].self, forKey: "layers")
      self.size = try container.decodeIfPresent(RestSchema.TileSourceSize.self, forKey: "size")
      self.tiles = try container.decode([String].self, forKey: "tiles")
      self.type = try container.decode(RestSchema.TileSourceType.self, forKey: "type")
      self.zoom_max = try container.decode(Int.self, forKey: "zoom_max")
      self.zoom_min = try container.decode(Int.self, forKey: "zoom_min")
    }

    /// Writes a `TileSource` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.attribution, forKey: "attribution")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.layers, forKey: "layers")
      try container.encodeIfPresent(self.size, forKey: "size")
      try container.encode(self.tiles, forKey: "tiles")
      try container.encode(self.type, forKey: "type")
      try container.encode(self.zoom_max, forKey: "zoom_max")
      try container.encode(self.zoom_min, forKey: "zoom_min")
    }
  }
}
