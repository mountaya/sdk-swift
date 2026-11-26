import Foundation
import MountayaClient

/// TileFixtures builds the Tile API's values a layer rule reads, with a placeholder in every member
/// the type requires and no rule here reads.
enum TileFixtures {
  static let noLocales = TileSchema.Locales(
    de: nil, en: nil, es: nil, fr: nil, it: nil, ja: nil, zh: nil)

  static func layer(
    _ sourceLayer: String, type: TileSchema.TileLayerType = .line, zoomMin: Int = 0,
    zoomMax: Int = 22
  ) -> TileSchema.TileLayer {
    TileSchema.TileLayer(
      id: "layer", key: "", layout: nil, paint: nil, source_layer: sourceLayer, type: type,
      zoom_max: zoomMax, zoom_min: zoomMin)
  }

  static func source(_ layers: [TileSchema.TileLayer], zoomMin: Int = 0, zoomMax: Int = 14)
    -> TileSchema.TileSource
  {
    TileSchema.TileSource(
      id: "source", layers: layers, tiles: [], type: .vector, zoom_max: zoomMax,
      zoom_min: zoomMin)
  }

  static func overlay(_ slug: String, id: String? = nil) -> TileSchema.Overlay {
    TileSchema.Overlay(
      capabilities: TileSchema.OverlayCapabilities(
        client: TileSchema.OverlaySupportedCapabilities(timestamp: false),
        server: TileSchema.OverlaySupportedCapabilities(timestamp: false)),
      content_type: .png, id: id ?? slug, locales: noLocales, slug: slug,
      sources: [])
  }

  static func category(
    _ slug: String, children: [TileSchema.Overlay], locales: TileSchema.Locales = noLocales
  ) -> TileSchema.CategoryOverlays {
    TileSchema.CategoryOverlays(children: children, id: slug, locales: locales, slug: slug)
  }

  static func layers(
    _ overlays: [TileSchema.CategoryOverlays], terrains: [TileSchema.Terrain] = []
  ) -> TileSchema.Layers {
    TileSchema.Layers(
      elevation: TileSchema.Elevation(
        id: "55763749-32b4-42d5-9f62-b6c51ef54d99", tile_size: .size512,
        url: URI(URL(fileURLWithPath: "/elevation"))),
      itineraries: overlay("itineraries"), overlays: overlays, terrains: terrains,
      zones: overlay("zones"))
  }

  /// names is the locales of an entry named `english` in English and `french` in French.
  static func names(english: String? = nil, french: String? = nil) -> TileSchema.Locales {
    TileSchema.Locales(
      de: nil, en: english.map { ["name": $0] }, es: nil, fr: french.map { ["name": $0] }, it: nil,
      ja: nil, zh: nil)
  }

  /// terrain is the terrain `slug` names, under `locales`, its variants placeholders no rule here
  /// reads.
  static func terrain(_ slug: String, locales: TileSchema.Locales = noLocales)
    -> TileSchema.Terrain
  {
    let variant = TileSchema.TerrainVariantConfig(
      style: TileSchema.TerrainVariantAsStyle(url: URI(URL(fileURLWithPath: "/\(slug)/style"))),
      tiles: TileSchema.TerrainVariantAsTiles(
        size: .size512, url: URI(URL(fileURLWithPath: "/\(slug)/tiles"))))
    return TileSchema.Terrain(
      id: slug, locales: locales, slug: slug,
      variants: TileSchema.TerrainVariants(dark: variant, light: variant))
  }

  /// named is the overlay `slug` names, under `locales`.
  static func named(_ slug: String, locales: TileSchema.Locales) -> TileSchema.Overlay {
    var named = overlay(slug)
    named.locales = locales
    return named
  }
}
