import MountayaClient
import MountayaGeo

/// MapSource is where a map's layers read their data: the Tile API's tiles, a raster's, an
/// elevation raster's, or GeoJSON the app holds.
///
/// A tile source's `tiles` are the URL templates a renderer fetches for itself, `{z}`, `{x}` and
/// `{y}` in their places, as a tile specification answers them: a template on the Tile API's
/// origin is fetched with the client's credential, and one on any other host with none. Two are
/// equal where they state the same, a text by its scalars, as every Geo value compares.
public struct MapSource: Sendable, Equatable, Identifiable {
  /// Kind is what a source serves.
  public enum Kind: Sendable, Equatable {
    /// vector is vector tiles, at the zoom levels they are served at.
    case vector(tiles: [String], zoom: ZoomBounds)
    /// raster is raster tiles of `tileSize` pixels, at the zoom levels they are served at, the
    /// renderer's own size where it is nil.
    case raster(tiles: [String], tileSize: Int?, zoom: ZoomBounds)
    /// rasterDem is an elevation raster's tiles of `tileSize` pixels, which a hillshade shades,
    /// the renderer's own size where it is nil.
    case rasterDem(tiles: [String], tileSize: Int?, zoom: ZoomBounds)
    /// geoJson is features the app holds, drawn as they are.
    case geoJson(GeoJSONFeatureCollection)

    /// Two kinds are equal where they serve the same, each template by its scalars.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.vector(let a, let zoomA), .vector(let b, let zoomB)):
        return sameTemplates(a, b) && zoomA == zoomB
      case (.raster(let a, let sizeA, let zoomA), .raster(let b, let sizeB, let zoomB)),
        (.rasterDem(let a, let sizeA, let zoomA), .rasterDem(let b, let sizeB, let zoomB)):
        return sameTemplates(a, b) && sizeA == sizeB && zoomA == zoomB
      case (.geoJson(let a), .geoJson(let b)):
        return a == b
      default:
        return false
      }
    }

    private static func sameTemplates(_ a: [String], _ b: [String]) -> Bool {
      a.count == b.count && zip(a, b).allSatisfy { sameText($0, $1) }
    }
  }

  /// id names the source, which a layer draws from by it.
  public var id: String
  /// kind is what the source serves.
  public var kind: Kind
  /// attribution is the credit the source's data asks for, or nil where it asks none.
  public var attribution: String?

  /// Creates a source of id `id` serving `kind`.
  public init(id: String, kind: Kind, attribution: String? = nil) {
    self.id = id
    self.kind = kind
    self.attribution = attribution
  }

  /// Creates the source a tile specification declares, its layers apart: a vector source, a
  /// raster's, or an elevation raster's of the size it states, the renderer's own where it states
  /// none (`map.specification.style`).
  ///
  /// It throws a `MapError` of kind `typeRefused`, naming the type as the answer wrote it, for a
  /// type the contract does not declare, which a newer Tile API may add: read as one this build
  /// knows, its tiles would be fetched and decoded as what they are not, with nothing reported.
  public init(_ source: TileSchema.TileSource) throws(MapError) {
    let zoom = ZoomBounds(minZoom: Double(source.zoom_min), maxZoom: Double(source.zoom_max))
    let size = source.size?.rawValue
    let kind: Kind
    if sameText(source.type, .vector) {
      kind = .vector(tiles: source.tiles, zoom: zoom)
    } else if sameText(source.type, .raster) {
      kind = .raster(tiles: source.tiles, tileSize: size, zoom: zoom)
    } else if sameText(source.type, .rasterDem) {
      kind = .rasterDem(tiles: source.tiles, tileSize: size, zoom: zoom)
    } else {
      throw MapError(kind: .typeRefused, name: source.type.rawValue)
    }
    self.init(id: source.id, kind: kind, attribution: source.attribution)
  }

  /// Two sources are equal where their ids, what they serve and their credits are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && lhs.kind == rhs.kind
      && sameText(lhs.attribution, rhs.attribution)
  }
}
