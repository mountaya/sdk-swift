import MountayaClient
import MountayaGeo

/// MapLayer is one layer a map draws above its base map: the source it draws from, how it draws,
/// the concept it draws, and the rank it draws at.
///
/// It is a layer as MapLibre's style document writes one: `type`, the `paint` and `layout`
/// properties under their style names (`line-color`, `visibility`), a `filter` expression and the
/// zoom window it draws across. A layer of a greater `rank` draws above one of a lesser, two of
/// one rank in the order they were placed, the later above, and every one above the base map's
/// own layers, which take no rank: the bands are `LayerRank`'s, and a tile specification's layers
/// take the rank their source layer declares (`geo.layers.order`).
///
/// Two are equal where they state the same, a text by its scalars and each number as the same
/// number, as every Geo value compares.
public struct MapLayer: Sendable, Equatable, Identifiable {
  /// id names the layer on the map, and replaces the layer added under it before.
  public var id: String
  /// type is how the layer draws: a line, a fill, a circle, a symbol, a raster or a hillshade.
  public var type: TileSchema.TileLayerType
  /// source is the id of the source the layer draws from.
  public var source: String
  /// sourceLayer is the layer of a vector source's tiles it draws, or nil for a source with none.
  public var sourceLayer: String?
  /// key is the concept the layer draws, as the layers manifest names it (`parking`,
  /// `hillshade`), which several layers of one overlay may share, or nil for a layer that draws
  /// no named concept (`map.layers.keys`).
  public var key: String?
  /// rank is the band the layer draws at, `LayerRank`'s number for one of its bands.
  public var rank: Int
  /// paint is the layer's paint properties, by their style names.
  public var paint: [String: JSONValue]
  /// layout is the layer's layout properties, by their style names.
  public var layout: [String: JSONValue]
  /// filter is the expression a feature is drawn under, or nil for every feature.
  public var filter: JSONValue?
  /// zoom is the zoom window the layer draws across, or nil for every zoom.
  public var zoom: ZoomBounds?

  /// Creates a layer drawing from `source` at `rank`, a band of `LayerRank` such as
  /// `LayerRank.itineraryLine.rank`, or a number between two of them.
  public init(
    id: String,
    type: TileSchema.TileLayerType,
    source: String,
    sourceLayer: String? = nil,
    key: String? = nil,
    rank: Int,
    paint: [String: JSONValue] = [:],
    layout: [String: JSONValue] = [:],
    filter: JSONValue? = nil,
    zoom: ZoomBounds? = nil
  ) {
    self.id = id
    self.type = type
    self.source = source
    self.sourceLayer = sourceLayer
    self.key = key
    self.rank = rank
    self.paint = paint
    self.layout = layout
    self.filter = filter
    self.zoom = zoom
  }

  /// Creates the layer a tile specification declares, drawing from the source it names or, where
  /// it names none, from the source of id `source` it is listed under, at the rank
  /// `tileLayerRank(_:ranks:)` reads off `ranks`, the contract's table unless a consumer patches
  /// it (`map.specification.style`).
  ///
  /// A null paint or layout is none. A raster or a hillshade layer reads a raster source, so it
  /// carries no source layer and no filter, both of which name what lies inside a vector tile; an
  /// empty source layer is the wire's way of saying there is none, and its empty key the same of a
  /// concept.
  public init(
    _ layer: TileSchema.TileLayer, source: String, ranks: [String: Int] = tileSourceLayerRanks
  ) {
    let readsRaster =
      sameText(layer.type, .raster) || sameText(layer.type, .hillshade)
    self.init(
      id: layer.id,
      type: layer.type,
      source: layer.source ?? source,
      sourceLayer: readsRaster || layer.source_layer.isEmpty ? nil : layer.source_layer,
      key: layer.key.isEmpty ? nil : layer.key,
      rank: tileLayerRank(layer, ranks: ranks),
      paint: layer.paint ?? [:],
      layout: layer.layout ?? [:],
      filter: readsRaster ? nil : layer.filter.map { .array($0) },
      zoom: ZoomBounds(minZoom: Double(layer.zoom_min), maxZoom: Double(layer.zoom_max))
    )
  }

  /// isHidden is whether the layer's layout hides it, `visibility` written `none`.
  public var isHidden: Bool {
    if case .string(let visibility)? = layout["visibility"] {
      return sameText(visibility, "none")
    }
    return false
  }

  /// Two layers are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && sameText(lhs.type, rhs.type) && sameText(lhs.source, rhs.source)
      && sameText(lhs.sourceLayer, rhs.sourceLayer) && sameText(lhs.key, rhs.key)
      && lhs.rank == rhs.rank && sameJson(lhs.paint, rhs.paint) && sameJson(lhs.layout, rhs.layout)
      && sameFilter(lhs.filter, rhs.filter) && lhs.zoom == rhs.zoom
  }

  /// sameFilter tells whether two filters are both absent, or both present and the same JSON.
  private static func sameFilter(_ a: JSONValue?, _ b: JSONValue?) -> Bool {
    switch (a, b) {
    case (.none, .none): true
    case (.some(let a), .some(let b)): sameJson(a, b)
    default: false
    }
  }
}
