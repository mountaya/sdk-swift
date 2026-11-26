import Foundation
import MountayaClient
import MountayaGeo

/// MapState is what a map shows: its base map and the catalogue terrain it is, its camera and the
/// limits it is held to, the language its labels speak, what it draws above the base map, the
/// sources and the layers in the order they draw, the markers it shows above them, the waypoint
/// being placed on it, and whether a refusal of access stands.
///
/// It is the state `MapEngine` holds and `MapView` renders, so a consumer who draws a map of
/// their own reads the same state. Two are equal where they show the same, each part compared as
/// every Geo value compares.
public struct MapState: Sendable, Equatable {
  /// style is the base map's style document, which the renderer fetches for itself, or nil
  /// before one is chosen, where nothing but what the map draws above it is shown.
  public var style: URL?
  /// terrain is the slug of the catalogue terrain the base map is, from the moment the map finds
  /// it in the layers catalogue, or nil under a style of the app's own and before any terrain
  /// (`map.basemap.terrain`).
  public var terrain: String?
  /// terrainVariant is the variant of a catalogue terrain the map draws: the one the base map's
  /// document is where its terrain's two variants are two documents, and otherwise the one the app
  /// asked for last, light until it asks for dark (`map.basemap.terrain`).
  public var terrainVariant: TileSchema.TerrainVariant
  /// camera is where the camera stands: its center, its zoom, its pitch and its bearing.
  public var camera: CameraPose
  /// maxBounds is the pan lock the camera is held within, `[west, south, east, north]` as the
  /// renderer is handed it, its east edge past 180 where it crosses the antimeridian, or nil for
  /// none.
  public var maxBounds: [Double]?
  /// zoomBounds is the zoom range the camera is held to, the renderer's own where none is set:
  /// MapLibre Native's, from 0, under which it draws nothing, to 25.5 (`map.camera.zoom-window`).
  public var zoomBounds: ZoomBounds
  /// labelLanguage is the language the map's labels speak (`geo.style.label-language`).
  public var labelLanguage: RestSchema.Language
  /// sources is every source the map's layers read, in the order they were added.
  public var sources: [MapSource]
  /// layers is every layer the map draws above its base map, bottom to top, in the order the
  /// one layer registry ranks them (`geo.layers.order`).
  public var layers: [MapLayer]
  /// markers is every marker the map shows, above everything it draws, in the order they were
  /// added, the last one on top.
  public var markers: [MapMarker]
  /// activeSegments is the lines an edit's magnet places a waypoint on, each a list of positions,
  /// none where the magnet is off (`map.edit.snap`).
  public var activeSegments: [[[Double]]]
  /// waypointEdit is the waypoint being placed, or nil where none is.
  public var waypointEdit: WaypointEdit?
  /// isAccessRequired is whether a refusal of access stands: one of the map's own requests was
  /// refused a 401, a 402 or a 403, and the source it came from has loaded no tile since, or, for
  /// a refusal naming no source, no style has loaded since (`map.events.access-standing`).
  public var isAccessRequired: Bool

  /// Creates a state showing `style`, the catalogue's `terrain` in `terrainVariant` where it is
  /// one, from `camera`, labelled in `labelLanguage`, drawing `layers` from `sources` in the order
  /// given and `markers` above them, held within `maxBounds` and `zoomBounds`, with the magnet on
  /// `activeSegments`, `waypointEdit` being placed, and a refusal of access standing where
  /// `isAccessRequired` says so.
  public init(
    style: URL?,
    terrain: String? = nil,
    terrainVariant: TileSchema.TerrainVariant = .light,
    camera: CameraPose,
    labelLanguage: RestSchema.Language,
    sources: [MapSource] = [],
    layers: [MapLayer] = [],
    markers: [MapMarker] = [],
    maxBounds: [Double]? = nil,
    zoomBounds: ZoomBounds = ZoomBounds(minZoom: 0, maxZoom: 25.5),
    activeSegments: [[[Double]]] = [],
    waypointEdit: WaypointEdit? = nil,
    isAccessRequired: Bool = false
  ) {
    self.style = style
    self.terrain = terrain
    self.terrainVariant = terrainVariant
    self.camera = camera
    self.maxBounds = maxBounds
    self.zoomBounds = zoomBounds
    self.labelLanguage = labelLanguage
    self.sources = sources
    self.layers = layers
    self.markers = markers
    self.activeSegments = activeSegments
    self.waypointEdit = waypointEdit
    self.isAccessRequired = isAccessRequired
  }

  /// Two states are equal where every part is the same, a word of the open vocabulary by its
  /// scalars and a number by the same-number relation.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.style == rhs.style && sameText(lhs.terrain, rhs.terrain)
      && sameText(lhs.terrainVariant, rhs.terrainVariant) && lhs.camera == rhs.camera
      && sameLock(lhs.maxBounds, rhs.maxBounds) && lhs.zoomBounds == rhs.zoomBounds
      && sameText(lhs.labelLanguage, rhs.labelLanguage) && lhs.sources == rhs.sources
      && lhs.layers == rhs.layers && lhs.markers == rhs.markers
      && sameLines(lhs.activeSegments, rhs.activeSegments) && lhs.waypointEdit == rhs.waypointEdit
      && lhs.isAccessRequired == rhs.isAccessRequired
  }

  private static func sameLock(_ a: [Double]?, _ b: [Double]?) -> Bool {
    switch (a, b) {
    case (nil, nil): return true
    case (let a?, let b?): return sameNumbers(a, b)
    default: return false
    }
  }

  private static func sameLines(_ a: [[[Double]]], _ b: [[[Double]]]) -> Bool {
    a.count == b.count
      && zip(a, b).allSatisfy { line, other in
        line.count == other.count && zip(line, other).allSatisfy { sameNumbers($0, $1) }
      }
  }
}
