// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// A single render-layer to add with `map.addLayer()`. Carries the style type,
  /// paint and layout objects, the source it draws from, the vector `source_layer`
  /// to pull, the zoom bounds, and an optional legend.
  public struct TileLayer: Sendable, Hashable, Codable {
    /// Optional MapLibre/Mapbox filter expression restricting which features the
    /// layer renders. Pass through to the `filter` option of `map.addLayer()`.
    /// Omitted when no filter applies; never null and never an empty array.
    public var filter: [JSONValue]?
    /// Unique layer identifier. Use it as the first argument to `map.addLayer()`.
    ///
    /// A composite path rather than a UUID, for example
    /// `itineraries/<itinerary_id>/lines`. Treat it as an opaque string: the
    /// shape is a rendering detail and is free to change, and it is the only
    /// kind of `id` on this surface that a UUID parser would reject.
    public var id: String
    /// Stable, human-readable concept slug grouping render-layers that depict the
    /// same map concept (e.g. "parking", "hillshade"). Unlike `id`, which is the
    /// per-layer unique identifier, `key` MAY repeat across several layers of the
    /// same overlay when one concept is rendered with multiple layers (a fill
    /// plus a symbol, for instance). Clients group and toggle layers by `key`;
    /// `id` remains the uniqueness guarantee.
    ///
    /// The empty string is a real value, and means this layer belongs to no
    /// named concept: an itinerary's own line layers carry it. Group by `key`
    /// only after discarding the empty ones, or every unnamed layer collapses
    /// into one group.
    public var key: String
    /// MapLibre/Mapbox layout properties for this layer (e.g. `visibility`,
    /// symbol placement). Pass through to the `layout` option of
    /// `map.addLayer()`. Null when the layer needs no layout overrides.
    public var layout: [String: JSONValue]?
    /// Optional legend describing how to read the layer's colors or scale. Drives
    /// the map UI legend; not consumed by `map.addLayer()`. Omitted when the
    /// layer has no legend; never null.
    public var legend: TileSchema.TileLegend?
    /// MapLibre/Mapbox paint properties for this layer (colors, opacity, widths,
    /// data-driven expressions). Pass through to the `paint` option of
    /// `map.addLayer()`. Null when the layer relies on style defaults.
    public var paint: [String: JSONValue]?
    /// Identifier of the source this layer draws from. Matches the `id` of the
    /// enclosing tile source.
    public var source: String?
    /// Name of the layer within a vector tile to render (e.g. "fills", "points",
    /// "lines"). Pass through to the `source-layer` option of `map.addLayer()`.
    /// Only meaningful for vector sources.
    public var source_layer: String
    /// How this layer draws, and what `paint` may carry: a map library maps it
    /// onto its own layer type, so pass it through rather than inferring one from
    /// the source.
    public var type: TileSchema.TileLayerType
    /// Highest zoom level at which the layer is drawn. Pass to the `maxzoom`
    /// option of `map.addLayer()`.
    public var zoom_max: Int
    /// Lowest zoom level at which the layer is drawn. Pass to the `minzoom`
    /// option of `map.addLayer()`.
    public var zoom_min: Int

    /// Creates a `TileLayer` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      id: String,
      key: String,
      layout: [String: JSONValue]?,
      paint: [String: JSONValue]?,
      source_layer: String,
      type: TileSchema.TileLayerType,
      zoom_max: Int,
      zoom_min: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.filter = nil
      self.id = id
      self.key = key
      self.layout = layout
      self.legend = nil
      self.paint = paint
      self.source = nil
      self.source_layer = source_layer
      self.type = type
      self.zoom_max = zoom_max
      self.zoom_min = zoom_min
      configure(&self)
    }

    /// Reads a `TileLayer` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.filter = try container.decodeIfPresent([JSONValue].self, forKey: "filter")
      self.id = try container.decode(String.self, forKey: "id")
      self.key = try container.decode(String.self, forKey: "key")
      self.layout = try container.decodeIfPresent([String: JSONValue].self, forKey: "layout")
      self.legend = try container.decodeIfPresent(TileSchema.TileLegend.self, forKey: "legend")
      self.paint = try container.decodeIfPresent([String: JSONValue].self, forKey: "paint")
      self.source = try container.decodeIfPresent(String.self, forKey: "source")
      self.source_layer = try container.decode(String.self, forKey: "source_layer")
      self.type = try container.decode(TileSchema.TileLayerType.self, forKey: "type")
      self.zoom_max = try container.decode(Int.self, forKey: "zoom_max")
      self.zoom_min = try container.decode(Int.self, forKey: "zoom_min")
    }

    /// Writes a `TileLayer` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.filter, forKey: "filter")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.key, forKey: "key")
      try container.encodeNullable(self.layout, forKey: "layout")
      try container.encodeIfPresent(self.legend, forKey: "legend")
      try container.encodeNullable(self.paint, forKey: "paint")
      try container.encodeIfPresent(self.source, forKey: "source")
      try container.encode(self.source_layer, forKey: "source_layer")
      try container.encode(self.type, forKey: "type")
      try container.encode(self.zoom_max, forKey: "zoom_max")
      try container.encode(self.zoom_min, forKey: "zoom_min")
    }
  }
}
