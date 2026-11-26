import Foundation
import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

/// The hit-tests a hovering pointer may cost a frame: one, at the place it ended the frame on, over
/// every layer a hover is told of at once.
///
/// A hit-test is a query of the renderer, and a pointer moves many times a frame, so a hit-test per
/// move, or per hovered layer, multiplies the renderer's work by either.
private let hoverHitTestBudget = 1

@Suite("MapEngine")
@MainActor
struct MapEngineTests {
  /// Catalogue answers the Tile API's `getTileLayers` with two terrains, and records each request.
  private final class Catalogue: HTTPExchange {
    static let body = #"""
      {"data": {
        "elevation": {"id": "55763749-32b4-42d5-9f62-b6c51ef54d99", "tile_size": 512, "url": "https://tiles.mountaya.com/v1/elevation/tiles.json"},
        "itineraries": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
          "content_type": "application/x-protobuf", "id": "i", "locales": {}, "slug": "itineraries", "sources": []},
        "zones": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
          "content_type": "application/x-protobuf", "id": "z", "locales": {}, "slug": "zones", "sources": []},
        "overlays": [],
        "terrains": [
          {"id": "t1", "slug": "outdoor", "locales": {}, "variants": {
            "light": {"style": {"url": "https://tiles.mountaya.com/v1/terrains/outdoor/light/style"},
              "tiles": {"size": 512, "url": "https://tiles.mountaya.com/v1/terrains/outdoor/light/tiles.json"}},
            "dark": {"style": {"url": "https://tiles.mountaya.com/v1/terrains/outdoor/dark/style"},
              "tiles": {"size": 512, "url": "https://tiles.mountaya.com/v1/terrains/outdoor/dark/tiles.json"}}}},
          {"id": "t2", "slug": "winter", "locales": {}, "variants": {
            "light": {"style": {"url": "https://tiles.mountaya.com/v1/terrains/winter/light/style"},
              "tiles": {"size": 512, "url": "https://tiles.mountaya.com/v1/terrains/winter/light/tiles.json"}},
            "dark": {"style": {"url": "https://tiles.mountaya.com/v1/terrains/winter/dark/style"},
              "tiles": {"size": 512, "url": "https://tiles.mountaya.com/v1/terrains/winter/dark/tiles.json"}}}}
        ]
      }}
      """#

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(Self.body.utf8)))
    }
  }

  private static func client(language: String? = "fr") throws -> Mountaya {
    try Mountaya(
      credential: .publishable(key: "pk_test_a"), language: language, exchange: Catalogue())
  }

  private static func url(_ text: String) throws -> URL {
    try #require(URL(string: text))
  }

  private static let line = MapLayer(
    id: "route", type: .line, source: "route", rank: LayerRank.itineraryLine.rank,
    paint: ["line-color": "#e64980", "line-width": 4])

  @Test("an engine opens on its camera and its style, drawing nothing above its base map")
  func opens() throws {
    let camera = CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 30, bearing: 15)
    let style = try Self.url("https://example.com/style.json")
    let map = MapEngine(client: try Self.client(), style: style, camera: camera)

    #expect(map.state == MapState(style: style, camera: camera, labelLanguage: .fr))
  }

  @Test("the marker sprites draw from the bundled marker set, or from the set the app hands in")
  func glyphs() throws {
    let licensed = try #require(
      GlyphSet(name: "licensed", paint: .stroke, markup: ["hut": #"<path d="M0 0h1"/>"#]))
    let chained = try #require(GlyphSet(chaining: [licensed, .marker]))

    #expect(MapEngine(client: try Self.client()).glyphs == .marker)
    #expect(MapEngine(client: try Self.client(), glyphs: licensed).glyphs == licensed)
    #expect(MapEngine(client: try Self.client(), glyphs: chained).glyphs.name == "licensed+marker")
  }

  @Test("the labels speak the language named, else the client's, else the device's")
  func labelLanguage() throws {
    #expect(
      MapEngine(client: try Self.client(language: "de-CH")).state.labelLanguage == .de)
    #expect(
      MapEngine(client: try Self.client(), labelLanguage: .ja).state.labelLanguage
        == .ja)
    #expect(
      MapEngine(client: try Self.client(), labelLanguage: RestSchema.Language(rawValue: "pt"))
        .state.labelLanguage == .en)
    #expect(
      MapEngine(client: try Self.client(language: nil)).state.labelLanguage
        == MountayaGeo.labelLanguage(Locale.preferredLanguages.first))

    let map = MapEngine(client: try Self.client(), labelLanguage: .it)
    map.setLabelLanguage(nil)
    #expect(map.state.labelLanguage == .fr)
    map.setLabelLanguage(.zh)
    #expect(map.state.labelLanguage == .zh)
  }

  @Test("a terrain of the catalogue is the base map: the first unless named, light until dark")
  func terrain() async throws {
    let map = MapEngine(client: try Self.client())
    try await map.setTerrain()
    #expect(
      map.state.style
        == (try Self.url("https://tiles.mountaya.com/v1/terrains/outdoor/light/style")))
    #expect(map.state.terrain == "outdoor")
    #expect(map.state.terrainVariant == .light)

    try await map.setTerrainVariant(.dark)
    #expect(
      map.state.style
        == (try Self.url("https://tiles.mountaya.com/v1/terrains/outdoor/dark/style")))
    #expect(map.state.terrainVariant == .dark)

    try await map.setTerrain("winter")
    #expect(
      map.state.style == (try Self.url("https://tiles.mountaya.com/v1/terrains/winter/dark/style")))
    #expect(map.state.terrain == "winter")

    await #expect(throws: MapError(kind: .terrainNotFound, name: "moon")) {
      try await map.setTerrain("moon")
    }
    #expect(
      map.state.style == (try Self.url("https://tiles.mountaya.com/v1/terrains/winter/dark/style")))

    let own = try Self.url("https://example.com/own.json")
    map.setStyle(own)
    #expect(map.state.terrain == nil, "a style of the app's own is no terrain of the catalogue")
    try await map.setTerrainVariant(.light)
    #expect(map.state.style == own, "under a style of the app's own nothing is switched")
    #expect(map.state.terrainVariant == .light)
  }

  @Test("a base map that does not arrive gives the map back the one shown, its content kept")
  func styleFailed() async throws {
    let map = MapEngine(client: try Self.client())
    let surface = ScriptedMapSurface(drawing: map)
    try await map.setTerrain()
    surface.loadStyle()
    map.addLayer(Self.line)
    try await map.setTerrain("winter")
    #expect(map.state.terrain == "winter")
    surface.failStyle()
    #expect(map.state.terrain == "outdoor")
    #expect(
      map.state.style
        == (try Self.url("https://tiles.mountaya.com/v1/terrains/outdoor/light/style")))
    #expect(map.state.layers.map(\.id) == ["route"])
    surface.failStyle()
    #expect(map.state.terrain == "outdoor", "the base map shown stays where nothing was asked")
  }

  /// A renderer draws the states the engine reports a turn later, so a style may load once a later
  /// base map is asked for: the style that loaded is the one shown.
  @Test("a style loading once a later one is asked for is the one shown, and given back")
  func styleLoadedLate() throws {
    let map = MapEngine(client: try Self.client())
    let first = try Self.url("https://tiles.mountaya.com/v1/terrains/outdoor/light/style")
    let second = try Self.url("https://tiles.mountaya.com/v1/terrains/winter/light/style")
    map.setStyle(first)
    map.setStyle(second)
    map.styleLoaded(first, terrain: nil)
    map.styleFailed(second)
    #expect(map.state.style == first, "the style that loaded is given back")

    map.setStyle(second)
    map.styleFailed(first)
    #expect(map.state.style == second, "the failure of a style replaced since moves nothing")
  }

  @Test("every layer is ranked by the one registry, whatever order it was added in")
  func ranked() throws {
    let map = MapEngine(client: try Self.client())
    map.addSource(MapSource(id: "route", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    map.addLayer(
      MapLayer(
        id: "cursor", type: .circle, source: "route", rank: LayerRank.chrome.rank))
    map.addLayer(Self.line)
    map.addLayer(
      MapLayer(
        id: "shade", type: .hillshade, source: "route", rank: LayerRank.hillshade.rank)
    )

    #expect(map.state.layers.map(\.id) == ["shade", "route", "cursor"])
    #expect(map.state.sources.map(\.id) == ["route"])
  }

  @Test("a patch replaces each member it states and leaves each it leaves nil as held")
  func patch() throws {
    let map = MapEngine(client: try Self.client())
    map.addLayer(Self.line)
    try map.editLayer(
      "route", paint: ["line-color": "#228be6", "line-width": nil, "line-opacity": 0],
      layout: ["visibility": "none"])

    let layer = try #require(map.state.layers.first)
    #expect(layer.paint == ["line-color": "#228be6", "line-width": 4, "line-opacity": 0])
    #expect(layer.layout == ["visibility": "none"])

    try map.editLayer("route", paint: ["line-color": .some(.null)])
    #expect(map.state.layers.first?.paint["line-color"] == .null)
  }

  @Test("a patch of a layer not drawn is refused, and the map is left as it was")
  func patchRefused() throws {
    let map = MapEngine(client: try Self.client())
    map.addLayer(Self.line)
    let before = map.state

    #expect(throws: MapError(kind: .layerNotFound, name: "gone")) {
      try map.editLayer("gone", paint: ["line-width": 2])
    }
    #expect(map.state == before)
  }

  @Test(
    "a tile specification's sources and layers are drawn, each layer at its source layer's rank")
  func specification() throws {
    let lines = TileSchema.TileLayer(
      id: "itinerary-lines", key: "lines", layout: nil, paint: ["line-width": 3],
      source_layer: "itinerary_lines", type: .line, zoom_max: 22, zoom_min: 0)
    let points = TileSchema.TileLayer(
      id: "itinerary-points", key: "points", layout: nil, paint: nil,
      source_layer: "itinerary_points", type: .symbol, zoom_max: 22, zoom_min: 0)
    let fills = TileSchema.TileLayer(
      id: "zone-fills", key: "fills", layout: nil, paint: nil,
      source_layer: "fills", type: .fill, zoom_max: 22, zoom_min: 0)
    let specification = TileSchema.TileSpecification(sources: [
      TileSchema.TileSource(
        id: "itineraries", layers: [points, lines],
        tiles: ["https://tiles.mountaya.com/v1/itineraries/{z}/{x}/{y}"],
        type: .vector, zoom_max: 14, zoom_min: 0),
      TileSchema.TileSource(
        id: "zones", layers: [fills], tiles: ["https://tiles.mountaya.com/v1/zones/{z}/{x}/{y}"],
        type: .vector, zoom_max: 14, zoom_min: 0),
    ])
    let map = MapEngine(client: try Self.client())
    try map.setSpecification(specification, named: "content")

    #expect(map.state.sources.map(\.id) == ["itineraries", "zones"])
    #expect(
      map.state.layers.map(\.id) == [
        "zone-fills", "itinerary-lines", "itinerary-lines__road-access-stripe", "itinerary-points",
        "itinerary-lines__road-access-icon",
      ])
    #expect(map.state.layers.map(\.rank) == [40, 50, 55, 90, 90])
    #expect(map.specifications == ["content"])

    map.removeSource("itineraries")
    #expect(map.state.sources.map(\.id) == ["zones"])
    #expect(map.state.layers.map(\.id) == ["zone-fills"])

    map.removeSpecification(named: "content")
    #expect(map.state.sources.isEmpty)
    #expect(map.state.layers.isEmpty)
    #expect(map.specifications.isEmpty)
  }

  @Test("a stream is told the state now, then each one that differs, and ends at close")
  func stream() async throws {
    let map = MapEngine(client: try Self.client())
    // An edit begun before the close, so placing the waypoint after it meets the close alone.
    try map.beginWaypointEdit("w0", at: [6.86, 45.83])
    let states = map.subscribe()
    map.addLayer(Self.line)
    map.addLayer(Self.line)
    map.removeLayer("route")
    map.removeLayer("route")
    map.close()
    let closed = map.state
    map.addLayer(Self.line)
    // A closed engine does nothing, and refuses nothing: an edit of a layer it does not draw
    // throws no `layerNotFound`, and no other command throws either.
    #expect(throws: Never.self) {
      try map.editLayer("route", paint: ["line-width": 8])
      try map.editMarker("hut", label: "Refuge")
      try map.addMarker(MapMarker(id: "hut", position: [0, 100]))
      try map.setMaxBounds([5, 45, 7, 45])
      try map.setZoomBounds(min: 13, max: 12)
      try map.beginWaypointEdit("w1", at: [0, 100])
      try map.placeWaypoint(at: [0, 100], through: Self.identity)
    }
    // Nor does a command it would take act: the state stays as the close left it.
    try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83]))
    try map.setMaxBounds([6, 45, 7, 46])
    try map.setZoomBounds(min: 5, max: 12)
    try map.placeWaypoint(at: [6.9, 45.9], through: Self.identity)
    try map.beginWaypointEdit("w1")
    #expect(map.endWaypointEdit() == nil)
    #expect(map.state == closed)
    #expect(map.state.waypointEdit?.position == [6.86, 45.83])

    var told: [[String]] = []
    for await state in states {
      told.append(state.layers.map(\.id))
    }
    #expect(told == [[], ["route"], []])
    #expect(map.state.layers.isEmpty)
  }

  @Test("a marker is shown above the others, one under an id in use replacing it on top")
  func markers() throws {
    let map = MapEngine(client: try Self.client())

    try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83, 2_100], label: "Refuge"))
    try map.addMarker(MapMarker(id: "summit", position: [6.87, 45.83], color: "#e64980"))
    try map.addMarker(MapMarker(id: "hut", position: [6.85, 45.82]))

    #expect(map.state.markers.map(\.id) == ["summit", "hut"])
    #expect(map.state.markers.last?.position == [6.85, 45.82])
    #expect(map.state.markers.last?.label == nil, "a replacement is the marker as added")
    try map.addMarker(MapMarker(id: "col", position: [7, 46, 1_800]))
    #expect(map.state.markers.last?.position == [7, 46], "an altitude is left out")
  }

  @Test("a marker placed nowhere a map draws is refused by name, the map left as it was")
  func markerRefused() throws {
    let map = MapEngine(client: try Self.client())
    try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83]))
    let before = map.state

    for position: [Double] in [[0, 100], [.nan, 45], [6, .infinity], [6], []] {
      #expect(throws: MapError(kind: .positionRefused, name: "hut")) {
        try map.addMarker(MapMarker(id: "hut", position: position))
      }
    }
    #expect(throws: MapError(kind: .positionRefused, name: "hut")) {
      try map.editMarker("hut", position: [6, -91])
    }
    #expect(map.state == before)
    try map.addMarker(MapMarker(id: "east", position: [190, 90]))
    #expect(
      map.state.markers.last?.position == [190, 90], "a longitude past the range names a place")
  }

  @Test("an edit of a marker changes what it gives and keeps what it leaves nil")
  func markerEdited() throws {
    let map = MapEngine(client: try Self.client())
    try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83], color: "#e64980", label: "A"))
    try map.addMarker(MapMarker(id: "summit", position: [6.87, 45.84]))

    try map.editMarker("hut", label: "Refuge")
    try map.editMarker("hut", position: [6.9, 45.9])

    #expect(
      map.state.markers == [
        MapMarker(id: "hut", position: [6.9, 45.9], color: "#e64980", label: "Refuge"),
        MapMarker(id: "summit", position: [6.87, 45.84]),
      ], "an edited marker keeps its place")
    #expect(throws: MapError(kind: .markerNotFound, name: "lake")) {
      try map.editMarker("lake", label: "Lac")
    }
    map.removeMarker("lake")
    map.removeMarker("hut")
    #expect(map.state.markers.map(\.id) == ["summit"])
    #expect(throws: MapError(kind: .markerNotFound, name: "hut")) {
      try map.editMarker("hut", label: "Refuge")
    }
    map.clearMarkers()
    #expect(map.state.markers.isEmpty)
  }

  @Test("a pan lock is read as a box is, a turn wide is the whole world, and nil lifts it")
  func panLock() throws {
    let map = MapEngine(client: try Self.client())

    try map.setMaxBounds([7, 46, 6, 45])
    #expect(map.state.maxBounds == [6, 45, 7, 46], "a box drawn from its east corner")
    try map.setMaxBounds([179.5, -17, 180.5, -16])
    #expect(map.state.maxBounds == [179.5, -17, 180.5, -16], "across the antimeridian")
    try map.setMaxBounds([5, 80, 6, 95])
    #expect(map.state.maxBounds == [5, 80, 6, webMercatorMaxLatitude])
    try map.setMaxBounds([-200, -60, 200, 60])
    #expect(map.state.maxBounds == [-179.9999999999, -60, 179.9999999999, 60])
    try map.setMaxBounds([-.infinity, -60, 10, 60])
    #expect(map.state.maxBounds == [-179.9999999999, -60, 179.9999999999, 60])
    try map.setMaxBounds(nil)
    #expect(map.state.maxBounds == nil)
  }

  @Test("a pan lock that encloses no area is refused, the map left as it was")
  func panLockRefused() throws {
    let map = MapEngine(client: try Self.client())
    try map.setMaxBounds([6, 45, 7, 46])
    let before = map.state

    for bounds: [Double] in [
      [5, 45, 7, 45], [5, 45, 5, 46], [.nan, 45, 6, 46], [5, 91, 6, 95], [6],
    ] {
      #expect(throws: MapError(kind: .maxBoundsRefused, name: "\(bounds)")) {
        try map.setMaxBounds(bounds)
      }
    }
    #expect(map.state == before)
  }

  @Test(
    "a zoom range holds the camera, brought to its nearest end, and a release goes back to 0 to 25.5"
  )
  func zoomBounds() throws {
    let map = MapEngine(
      client: try Self.client(),
      camera: CameraPose(center: [6.86, 45.83], zoom: 16, pitch: 0, bearing: 0))
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: 0, maxZoom: 25.5), "MapLibre Native's own")

    try map.setZoomBounds(min: 5, max: 12)
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: 5, maxZoom: 12))
    #expect(map.state.camera.zoom == 12)
    try map.jump(to: CameraTarget(zoom: 2))
    #expect(map.state.camera.zoom == 5)
    try map.setZoomBounds(min: 8, max: 8)
    #expect(map.state.camera.zoom == 8, "a range of one zoom holds the camera at it")
    try map.setZoomBounds(max: 14)
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: 8, maxZoom: 14), "the floor is kept")
    try map.setZoomBounds(min: .released)
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: 0, maxZoom: 14))
    try map.setZoomBounds(min: 16.5, max: .released)
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: 16.5, maxZoom: 25.5))
    #expect(map.state.camera.zoom == 16.5)
    try map.setZoomBounds(min: .released, max: .released)
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: 0, maxZoom: 25.5))
    #expect(map.state.camera.zoom == 16.5)
  }

  @Test("a zoom range a camera cannot take is refused by kind, the map left as it was")
  func zoomBoundsRefused() throws {
    let map = MapEngine(client: try Self.client())
    try map.setZoomBounds(min: 3, max: 15)
    let before = map.state

    let refusals: [(ZoomLimit, ZoomLimit, MapError.Kind)] = [
      (.zoom(.nan), .kept, .numberRefused), (.kept, .zoom(.infinity), .numberRefused),
      (.zoom(-.infinity), .zoom(12), .numberRefused), (-1, .kept, .zoomBoundsRefused),
      (13, 12, .zoomBoundsRefused), (16, .kept, .zoomBoundsRefused), (.kept, 2, .zoomBoundsRefused),
    ]
    for (min, max, kind) in refusals {
      let error = #expect(throws: MapError.self) { try map.setZoomBounds(min: min, max: max) }
      #expect(error?.kind == kind, "\(min) to \(max)")
    }
    #expect(map.state == before)
    try map.setZoomBounds(min: 0, max: 0)
    #expect(
      map.state.zoomBounds == ZoomBounds(minZoom: 0, maxZoom: 0), "the renderer's floor is a floor")
  }

  /// identity reads a longitude as an x and a latitude as a y, one degree one pixel.
  private static let identity = ScreenProjection(point: { $0 }, position: { $0 })

  @Test("a waypoint is placed where a tap falls, on an active segment within 40 px of it")
  func waypointPlaced() throws {
    let map = MapEngine(client: try Self.client())
    map.setActiveSegments([[[0, 10], [100, 10]]])

    try map.beginWaypointEdit("w1")
    #expect(map.state.waypointEdit == WaypointEdit(waypointId: "w1"))
    try map.placeWaypoint(at: [50, 30], through: Self.identity)
    #expect(
      map.state.waypointEdit == WaypointEdit(waypointId: "w1", position: [50, 10], isSnapped: true))
    try map.placeWaypoint(at: [50, 51], through: Self.identity)
    #expect(map.state.waypointEdit == WaypointEdit(waypointId: "w1", position: [50, 51]))
    map.setActiveSegments([])
    try map.placeWaypoint(at: [50, 11], through: Self.identity)
    #expect(map.state.waypointEdit?.isSnapped == false, "no segment, no magnet")

    #expect(map.endWaypointEdit() == WaypointEdit(waypointId: "w1", position: [50, 11]))
    #expect(map.state.waypointEdit == nil)
    #expect(map.endWaypointEdit() == nil)
  }

  @Test("an edit begun goes on, another waypoint's begins in its place, and no edit places nothing")
  func waypointEdits() throws {
    let map = MapEngine(client: try Self.client())

    try map.placeWaypoint(at: [6, 45], through: Self.identity)
    #expect(map.state.waypointEdit == nil)
    try map.beginWaypointEdit("w1", at: [6, 45])
    try map.placeWaypoint(at: [190, 46], through: Self.identity)
    #expect(map.state.waypointEdit?.position == [-170, 46], "a tap's longitude within [-180, 180]")
    try map.beginWaypointEdit("w1", at: [7, 45])
    #expect(map.state.waypointEdit?.position == [-170, 46], "the edit begun goes on as it is")
    try map.beginWaypointEdit("w2")
    #expect(map.state.waypointEdit == WaypointEdit(waypointId: "w2"))
    #expect(throws: MapError(kind: .positionRefused, name: "w3")) {
      try map.beginWaypointEdit("w3", at: [6, 91])
    }
    #expect(throws: MapError(kind: .positionRefused, name: "w2")) {
      try map.placeWaypoint(at: [.nan, 45], through: Self.identity)
    }
    #expect(map.state.waypointEdit == WaypointEdit(waypointId: "w2"))
  }

  @Test("a camera the app moves is the state's, every member stated")
  func camera() throws {
    let map = MapEngine(client: try Self.client())
    try map.jump(to: CameraTarget(center: [6.86, 45.83], zoom: 12, bearing: 0, pitch: 0))

    #expect(map.state.camera == CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 0, bearing: 0))
  }

  // MARK: - The camera, the queries and the events (family 8c)

  /// Unreachable is a request that never reached an answer.
  private struct Unreachable: Error {}

  /// Answers is an exchange answering each request with a status, a Data API query with the
  /// terrain sample it is asked for, and recording each request.
  private actor Answers: HTTPExchange {
    let status: Int?
    private(set) var sent: [ExchangeRequest] = []

    init(status: Int? = nil) {
      self.status = status
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent.append(request)
      guard status == nil else {
        guard let status else { throw Unreachable() }
        return ExchangeResponse(
          status: status, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(
            Data(#"{"errors": [{"code": "PAYMENT_REQUIRED", "message": "no"}]}"#.utf8)))
      }
      let body = String(decoding: request.body ?? Data(), as: UTF8.self)
      let answer =
        body.contains("\"query\"")
        ? #"{"data": {"terrainSamples": {"samples": [{"elevation": 1834}]}}}"#
        : #"{"errors": [{"message": "PersistedQueryNotFound", "extensions": {"code": "PERSISTED_QUERY_NOT_FOUND"}}]}"#
      return ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(answer.utf8)))
    }
  }

  /// Specifications is an exchange answering every request with one tile specification, counting
  /// the requests it answered.
  private actor Specifications: HTTPExchange {
    let body: Data
    private(set) var sent = 0

    init(_ specification: TileSchema.TileSpecification) {
      let written = (try? JSONEncoder().encode(specification)) ?? Data("{}".utf8)
      body = Data(#"{"data": "#.utf8) + written + Data("}".utf8)
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent += 1
      return ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"], body: ExchangeBody(body))
    }
  }

  /// Fixed is a geolocation answering one fix, recording whether it was asked.
  private final class Fixed: Geolocation {
    let fix: GeolocationFix
    private(set) var asked = 0

    init(_ fix: GeolocationFix) {
      self.fix = fix
    }

    func locate() async -> GeolocationFix {
      asked += 1
      return fix
    }

    func permission() async -> GeolocationPermission { .granted }
  }

  /// Closing is a geolocation that closes the map it answers while the fix is on its way, as a
  /// reader leaving the screen does while the device looks for one.
  private final class Closing: Geolocation {
    weak var map: MapEngine?

    func locate() async -> GeolocationFix {
      map?.close()
      return .located(position: [6.86, 45.83], accuracyMeters: 25)
    }

    func permission() async -> GeolocationPermission { .granted }
  }

  private static func drawn(
    geolocation: any Geolocation = InertGeolocation(), exchange: (any HTTPExchange)? = nil
  )
    throws -> (MapEngine, ScriptedMapSurface)
  {
    let map = MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"),
        baseUrls: BaseURLs(tiles: try Self.url("https://tiles.test/")),
        exchange: exchange ?? Catalogue()),
      camera: CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 10, bearing: 20),
      labelLanguage: .en, geolocation: geolocation)
    return (map, ScriptedMapSurface(drawing: map))
  }

  private static let pointGeometry = GeoJSONGeometry.point(
    GeoJSONPoint(coordinates: [6.86, 45.83]))

  @Test(
    "a camera move hands the renderer the members it states, and the state holds where it lands")
  func moves() throws {
    let (map, surface) = try Self.drawn()
    try map.jump(to: CameraTarget(center: [197.5, 0], pitch: 0))
    try map.ease(to: CameraTarget(zoom: 30))
    try map.fly(to: CameraTarget(bearing: -30))
    #expect(
      surface.moves == [
        .init(target: CameraTarget(center: [197.5, 0], pitch: 0), motion: .jump),
        .init(target: CameraTarget(zoom: 30), motion: .ease(duration: nil)),
        .init(target: CameraTarget(bearing: -30), motion: .fly),
      ])
    #expect(
      map.state.camera == CameraPose(center: [197.5, 0], zoom: 25.5, pitch: 0, bearing: -30),
      "the state holds the zoom within the window, the move hands it as stated")
  }

  @Test("a camera move that names no place or no number is refused before anything moves")
  func movesRefused() throws {
    let (map, surface) = try Self.drawn()
    let before = map.state
    for (target, kind) in [
      (CameraTarget(center: [6, 90.0001]), MapError.Kind.positionRefused),
      (CameraTarget(center: [6.86, 45.83, 1035]), .positionRefused),
      (CameraTarget(center: [6.86, 45.83], zoom: .nan), .numberRefused),
      (CameraTarget(bearing: .infinity), .numberRefused),
    ] {
      let error = #expect(throws: MapError.self) { try map.fly(to: target) }
      #expect(error?.kind == kind)
    }
    #expect(surface.moves.isEmpty)
    #expect(map.state == before)
  }

  @Test("a fit frames on the surface's canvas facing north, and a map no view draws frames nothing")
  func fits() throws {
    let lonely = MapEngine(client: try Self.client(), geolocation: InertGeolocation())
    try lonely.fitBounds([6.8, 45.8, 6.95, 45.9])
    #expect(lonely.state.camera.zoom == 0, "no canvas, no fit")

    let (map, surface) = try Self.drawn()
    try map.fitBounds(
      [6.95, 45.9, 6.8, 45.8], with: CameraFit(padding: PixelPadding(48), maxZoom: 15))
    #expect(
      surface.frames == [
        .init(
          bounds: [6.8, 45.8, 6.95, 45.9], fit: CameraFit(padding: PixelPadding(48), maxZoom: 15))
      ])
    #expect(abs(map.state.camera.zoom - 11.269337026503) < 1e-9)
    #expect(map.state.camera.bearing == 0 && map.state.camera.pitch == 10)
    for (bounds, fit, kind) in [
      ([6.8, 45.8, 6.95] as [Double], CameraFit(), MapError.Kind.positionRefused),
      ([.nan, 45.8, 6.95, 45.9], CameraFit(), .positionRefused),
      ([6.8, 45.8, 6.95, 45.9], CameraFit(padding: PixelPadding(-1)), .numberRefused),
      ([6.8, 45.8, 6.95, 45.9], CameraFit(maxZoom: .infinity), .numberRefused),
      ([6.8, 45.8, 6.95, 45.9], CameraFit(duration: .milliseconds(-250)), .numberRefused),
    ] {
      let error = #expect(throws: MapError.self) { try map.fitBounds(bounds, with: fit) }
      #expect(error?.kind == kind)
    }
    #expect(surface.frames.count == 1)
  }

  @Test("a drawing call draws, then frames the box its specification states, its fit read first")
  func drawingFit() async throws {
    var specification = TileSchema.TileSpecification(sources: [
      TileSchema.TileSource(
        id: "collection",
        layers: [
          TileSchema.TileLayer(
            id: "lines", key: "lines", layout: nil, paint: nil, source_layer: "itinerary_lines",
            type: .line, zoom_max: 22, zoom_min: 0)
        ], tiles: ["https://tiles.test/c/{z}/{x}/{y}"], type: .vector, zoom_max: 14,
        zoom_min: 0)
    ])
    let unboxed = Specifications(specification)
    let (map, surface) = try Self.drawn(exchange: unboxed)
    await #expect(throws: MapError(kind: .numberRefused, name: "padding")) {
      try await map.setCollection("c", fit: CameraFit(padding: PixelPadding(.nan)))
    }
    #expect(map.state.layers.isEmpty, "a refused fit draws nothing")
    #expect(await unboxed.sent == 0, "a refused fit reads nothing")
    #expect(try await map.setCollection("c", fit: CameraFit()))
    #expect(surface.frames.isEmpty, "a specification stating no box frames nothing")

    specification.bbox = [179.8, -17, -179.9, -16]
    let boxed = Specifications(specification)
    let (across, framed) = try Self.drawn(exchange: boxed)
    #expect(try await across.setCollection("c", fit: CameraFit(maxZoom: 10)))
    let box = try #require(framed.frames.first?.bounds)
    #expect(box[0] == 179.8 && abs(box[2] - 180.1) < 1e-9 && box[3] == -16, "\(box)")
    #expect(try await across.setCollection("c"))
    #expect(framed.frames.count == 1, "no fit asked, none framed")
    across.close()
    #expect(try await across.setCollection("c", fit: CameraFit()) == false)
    #expect(await boxed.sent == 2, "a closed map reads nothing")
  }

  @Test(
    "a zoom control steps from the zoom held, within the window, and a reset turns north and level")
  func controls() throws {
    let (map, surface) = try Self.drawn()
    try map.setZoomBounds(min: 2, max: 12.5)
    map.zoomIn()
    #expect(map.state.camera.zoom == 12.5)
    map.zoomOut()
    map.zoomOut()
    #expect(map.state.camera.zoom == 10.5)
    map.resetNorth()
    #expect(
      map.state.camera == CameraPose(center: [6.86, 45.83], zoom: 10.5, pitch: 0, bearing: 0))
    #expect(
      surface.moves.map(\.target) == [
        CameraTarget(zoom: 12.5), CameraTarget(zoom: 11.5), CameraTarget(zoom: 10.5),
        CameraTarget(bearing: 0, pitch: 0),
      ])
    #expect(surface.moves.last?.motion == .ease(duration: .seconds(1)))
    #expect(surface.moves.first?.motion == .ease(duration: .milliseconds(250)))
    map.easeIntoZoomRange(ZoomBounds(minZoom: 14, maxZoom: 16))
    #expect(map.state.camera.zoom == 12.5, "eased to the window's floor, held within the map's")
    map.easeIntoZoomRange(ZoomBounds(minZoom: 8, maxZoom: 13))
    map.easeIntoZoomRange(ZoomBounds(minZoom: 9, maxZoom: 3))
    #expect(surface.moves.count == 5, "a camera inside a window, or before none, stays")
  }

  @Test("a zoom window plays on the renderer's own limits, the surface's where one draws the map")
  func rendererLimits() async throws {
    let map = MapEngine(client: try Self.client(), geolocation: InertGeolocation())
    let surface = ScriptedMapSurface(drawing: map, zoomLimits: ZoomBounds(minZoom: -2, maxZoom: 22))
    try map.setZoomBounds(min: -2, max: 12)
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: -2, maxZoom: 12))
    try map.setZoomBounds(max: .released)
    #expect(map.state.zoomBounds == ZoomBounds(minZoom: -2, maxZoom: 22))
    #expect(surface.zoomLimits.minZoom == -2)
    let states = map.subscribe()
    try map.setZoomBounds(min: -2)
    try map.setZoomBounds()
    try map.setZoomBounds(min: 4)
    map.close()
    var told = 0
    for await _ in states { told += 1 }
    #expect(told == 2, "the state now, and one window moved")
  }

  @Test(
    "where the reader asked for reduced motion, every move a control starts lands at once, the app's own as it asks"
  )
  func reducedMotion() async throws {
    let fixed = Fixed(.located(position: [6.86, 45.83], accuracyMeters: 100))
    let (map, surface) = try Self.drawn(geolocation: fixed)
    map.reducesMotion = true
    map.zoomIn()
    map.zoomOut()
    map.resetNorth()
    map.easeIntoZoomRange(ZoomBounds(minZoom: 14, maxZoom: 16))
    try map.ease(to: CameraTarget(bearing: 10))
    try await map.locate()

    #expect(
      surface.moves.map(\.motion) == [.jump, .jump, .jump, .jump, .ease(duration: nil)],
      "the app's own ease travels as it asks")
    #expect(
      surface.moves.first?.target == CameraTarget(zoom: 13), "a jump lands where a step eases")
    #expect(surface.frames.last?.fit == CameraFit(maxZoom: 16, duration: .zero))

    map.reducesMotion = false
    map.zoomIn()
    #expect(surface.moves.last?.motion == .ease(duration: .milliseconds(250)))
  }

  @Test(
    "locating frames the fix's accuracy box at zoom 16 at most, and a refused fix moves nothing")
  func locates() async throws {
    let fixed = Fixed(.located(position: [-73.9749, 40.7736], accuracyMeters: 100))
    let (map, surface) = try Self.drawn(geolocation: fixed)
    #expect(try await map.locate() == [-73.9749, 40.7736])
    let frame = try #require(surface.frames.last)
    #expect(frame.fit == CameraFit(maxZoom: 16))
    #expect(
      abs(frame.bounds[0] - -73.976086214142) < 1e-9
        && abs(frame.bounds[3] - 40.774498315284) < 1e-9)

    for accuracy in [-5, Double.nan, .infinity] {
      let (vague, vagueSurface) = try Self.drawn(
        geolocation: Fixed(.located(position: [6.86, 45.83], accuracyMeters: accuracy)))
      try await vague.locate()
      #expect(vagueSurface.frames.map(\.bounds) == [[6.86, 45.83, 6.86, 45.83]], "\(accuracy)")
    }
    for reason in GeolocationRefusal.allCases {
      let (refused, refusedSurface) = try Self.drawn(geolocation: Fixed(.refused(reason)))
      let error = await #expect(throws: MapError.self) { try await refused.locate() }
      #expect(error?.kind == .fixRefused(reason))
      #expect(refusedSurface.frames.isEmpty && refusedSurface.moves.isEmpty)
    }
    let asking = Fixed(.located(position: [6.86, 45.83], accuracyMeters: 25))
    let (closed, _) = try Self.drawn(geolocation: asking)
    closed.close()
    let error = await #expect(throws: MapError.self) { try await closed.locate() }
    #expect(error?.kind == .closed)
    #expect(asking.asked == 0, "a closed map asks the device nothing")

    let closing = Closing()
    let (left, leftSurface) = try Self.drawn(geolocation: closing)
    closing.map = left
    let camera = left.state.camera
    #expect(try await left.locate() == [6.86, 45.83])
    #expect(leftSurface.frames.isEmpty, "a fix that arrives after the map closed frames nothing")
    #expect(left.state.camera == camera)
  }

  @Test("a point query asks about the layers placed in its bands the live style holds, none else")
  func queries() throws {
    let (map, surface) = try Self.drawn()
    map.addLayer(MapLayer(id: "line", type: .line, source: "s", rank: 50))
    map.addLayer(MapLayer(id: "fill", type: .fill, source: "s", rank: 40))
    map.addLayer(MapLayer(id: "hut", type: .symbol, source: "s", rank: 80))
    surface.rendered = [
      QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "hut"),
      QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "road"),
      QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "line"),
    ]
    #expect(map.features(at: [1, 2]).map(\.layer) == ["hut", "line"])
    #expect(map.itineraries(at: [1, 2]).map(\.layer) == ["line"])
    #expect(map.pois(at: [1, 2]).map(\.layer) == ["hut"])
    #expect(map.zones(at: [1, 2]).isEmpty)
    #expect(surface.queries == [["line", "fill", "hut"], ["line"], ["hut"], ["fill"]])
    map.close()
    #expect(map.features(at: [1, 2]).isEmpty)
    #expect(surface.queries.count == 4, "a closed map asks the renderer nothing")
  }

  @Test("a tap is told, and again with the map's features it landed on; an edit takes a gesture")
  func taps() async throws {
    let (map, surface) = try Self.drawn()
    map.addLayer(MapLayer(id: "line", type: .line, source: "s", rank: 50))
    try map.addMarker(MapMarker(id: "hut", position: [100, 80]))
    let events = map.events()
    surface.rendered = [
      QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "line")
    ]
    surface.tap(at: [110, 80], position: [-540.5, 10])
    surface.rendered = []
    surface.tap(at: [200, 200], position: [180, 45])
    surface.longTap(at: [200, 200], position: [-180, 45])
    try map.beginWaypointEdit("w1")
    surface.tap(at: [5, 6], position: [6, 45])
    surface.longTap(at: [5, 6], position: [6, 45])
    map.endWaypointEdit()
    map.close()
    var told: [MapEvent] = []
    for await event in events { told.append(event) }
    #expect(
      told == [
        .tap(MapTap(position: [179.5, 10], point: [110, 80], marker: "hut")),
        .featureTap(
          position: [179.5, 10],
          features: [QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "line")]),
        .tap(MapTap(position: [180, 45], point: [200, 200])),
        .longTap(MapTap(position: [-180, 45], point: [200, 200])),
      ])
  }

  @Test("a hover is told once a frame where it ended, and with none as it leaves")
  func hovers() async throws {
    let (map, surface) = try Self.drawn()
    map.addLayer(MapLayer(id: "point", type: .circle, source: "s", rank: 90))
    map.addLayer(MapLayer(id: "fill", type: .fill, source: "s", rank: 40))
    surface.hover(at: [1, 1], position: [6, 45])
    surface.drawFrame()
    #expect(surface.queries.isEmpty, "nothing is asked while nobody listens")
    let events = map.events()
    surface.rendered = [
      QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "point")
    ]
    surface.hover(at: [1, 1], position: [6, 45])
    surface.hover(at: [2, 2], position: [181, 45])
    surface.drawFrame()
    surface.drawFrame()
    surface.hover(at: [3, 3], position: [7, 46])
    surface.leave(at: [4, 4], position: [-190, 45])
    surface.drawFrame()
    map.close()
    var told: [MapEvent] = []
    for await event in events { told.append(event) }
    #expect(
      told == [
        .featureHover(
          position: [-179, 45],
          features: [QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "point")]),
        .featureHover(position: [170, 45], features: []),
      ])
    #expect(surface.queries == [["point"]])
  }

  @Test(
    "hot-path budget hover-hit-test: five moves a frame for sixty frames cost a hit-test a frame")
  func hoverHitTest() async throws {
    let (map, surface) = try Self.drawn()
    let hovered = ["trail-casing", "trail", "trail-points"]
    map.addLayer(MapLayer(id: "trail-casing", type: .line, source: "s", rank: 50))
    map.addLayer(MapLayer(id: "trail", type: .line, source: "s", rank: 50))
    map.addLayer(MapLayer(id: "trail-points", type: .symbol, source: "s", rank: 90))
    map.addLayer(MapLayer(id: "zones", type: .fill, source: "s", rank: 40))
    map.addLayer(MapLayer(id: "huts", type: .circle, source: "s", rank: 80))
    surface.rendered = [
      QueriedFeature(properties: [:], geometry: Self.pointGeometry, layer: "trail")
    ]
    let frames = 60
    /// burst moves the pointer five times a frame across the canvas, and draws each frame.
    func burst() {
      for frame in 0..<frames {
        for move in 0..<5 {
          let step = Double(frame * 5 + move)
          surface.hover(at: [step, 100], position: [6.8 + step / 1_000, 45.83])
        }
        surface.drawFrame()
      }
    }

    // Nothing is asked of the renderer while nobody listens.
    burst()
    #expect(surface.queries.isEmpty, "\(surface.queries.count) hit-tests with nobody listening")

    let events = map.events()
    burst()
    map.close()
    var told: [[Double]] = []
    for await event in events {
      if case .featureHover(let position, let features) = event, features.count == 1 {
        told.append(position)
      }
    }

    // The work happened: each frame told the features under the place the pointer ended it on.
    #expect(told.count == frames)
    #expect(told.last == [6.8 + Double(frames * 5 - 1) / 1_000, 45.83])
    // One hit-test a frame, over every layer a hover is told of at once.
    #expect(
      surface.queries.count <= hoverHitTestBudget * frames,
      "\(surface.queries.count) hit-tests over \(frames) frames")
    #expect(surface.queries.allSatisfy { $0 == hovered }, "\(Set(surface.queries))")
  }

  @Test("a refusal of access is told and stands until its source answers; any other is a failure")
  func access() async throws {
    let (map, surface) = try Self.drawn(exchange: Answers(status: 402))
    let events = map.events()
    await #expect(throws: (any Error).self) { try await map.setTerrain() }
    #expect(map.state.isAccessRequired)
    map.addSource(MapSource(id: "slope", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    surface.failRequest(url: "https://tiles.test/slope/1/2/3", status: 403, source: "slope")
    surface.failRequest(url: "https://tiles.test/slope/1/2/4", status: 404, source: "slope")
    surface.failRequest(url: "https://tiles.test/slope/1/2/5", status: nil, source: "slope")
    surface.loadStyle()
    #expect(map.state.isAccessRequired, "the source's refusal stands past the style")
    surface.loadTile(of: "slope")
    #expect(!map.state.isAccessRequired)
    map.close()
    var told: [MapEvent] = []
    for await event in events { told.append(event) }
    #expect(
      told == [
        .accessRefused(status: 402, url: "https://tiles.test/v1/tile-layers"),
        .accessRefused(status: 403, url: "https://tiles.test/slope/1/2/3"),
        .failure(url: "https://tiles.test/slope/1/2/4", status: 404),
        .failure(url: "https://tiles.test/slope/1/2/5", status: nil),
        .accessRestored,
      ])
  }

  /// Unreadable is what a read of the client's credential threw.
  private struct Unreadable: Error {}

  /// A request whose credential could not be read never leaves: whatever status it would have met,
  /// it is told as a failure carrying what the read threw, and stands for nothing, as `sdk-dart`'s
  /// map tells it.
  @Test("a request that never left for want of a credential fails carrying what the read threw")
  func refusedCause() async throws {
    let (map, surface) = try Self.drawn()
    let events = map.events()
    map.addSource(MapSource(id: "slope", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    surface.failRequest(
      url: "https://tiles.test/slope/1/2/3", status: 403, source: "slope", cause: Unreadable())
    surface.failRequest(url: "https://tiles.test/slope/1/2/4", status: nil, source: "slope")
    #expect(!map.state.isAccessRequired, "a request that never left refuses no access")
    map.close()
    var told: [MapEvent] = []
    for await event in events { told.append(event) }

    #expect(
      told == [
        .failure(url: "https://tiles.test/slope/1/2/3", status: nil),
        .failure(url: "https://tiles.test/slope/1/2/4", status: nil),
      ])
    let causes = told.map { event -> (any Error)? in
      guard case .failure(_, _, let cause) = event else { return nil }
      return cause
    }
    #expect(causes.first.flatMap { $0 } is Unreadable)
    #expect(causes.last.flatMap { $0 } == nil, "a request that left carries no cause")
  }

  @Test("a base map given back after a refused switch ends no refusal as it loads again")
  func refusalStandsThroughTheGivenBack() async throws {
    let (map, surface) = try Self.drawn()
    let events = map.events()
    let shown = try Self.url("https://tiles.test/shown.json")
    map.setStyle(shown)
    surface.loadStyle()
    map.addSource(MapSource(id: "slope", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    surface.failRequest(url: "https://tiles.test/slope/1/2/3", status: 403, source: "slope")
    map.setStyle(try Self.url("https://tiles.test/switch.json"))
    surface.failRequest(url: "https://tiles.test/switch.json", status: 402, source: nil)
    surface.failStyle()
    #expect(map.state.style == shown, "the base map shown is given back")
    surface.loadStyle()
    #expect(map.state.isAccessRequired, "the switch's refusal stands as the base map loads again")
    surface.loadTile(of: "slope")
    #expect(map.state.isAccessRequired, "a tile ends its source's refusal, never the switch's")
    map.setStyle(try Self.url("https://tiles.test/next.json"))
    surface.loadStyle()
    #expect(!map.state.isAccessRequired, "a style the map asks for ends it")
    map.close()
    var told: [MapEvent] = []
    for await event in events { told.append(event) }
    #expect(
      told == [
        .accessRefused(status: 403, url: "https://tiles.test/slope/1/2/3"),
        .accessRefused(status: 402, url: "https://tiles.test/switch.json"),
        .accessRestored,
      ])
  }

  /// A tile asked for while the first session token was on its way left under the key alone, and
  /// its refusal arrives once the token has landed: the map no longer sends what was refused.
  @Test("a 401 or a 403 of a credential the client no longer sends is told to nobody, nor stands")
  func supersededCredential() async throws {
    let (map, surface) = try Self.drawn()
    let events = map.events()
    map.addSource(MapSource(id: "slope", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    map.addSource(MapSource(id: "zones", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    surface.failRequest(
      url: "https://tiles.test/slope/1/2/3", status: 401, source: "slope", superseded: true)
    surface.failRequest(url: "https://tiles.test/x", status: 403, source: nil, superseded: true)
    #expect(!map.state.isAccessRequired, "a refusal told to nobody starts no standing")
    surface.failRequest(url: "https://tiles.test/slope/1/2/4", status: 401, source: "slope")
    surface.failRequest(
      url: "https://tiles.test/zones/1/2/3", status: 403, source: "zones", superseded: true)
    surface.loadTile(of: "slope")
    #expect(!map.state.isAccessRequired, "nor keeps one standing")
    surface.failRequest(
      url: "https://tiles.test/zones/1/2/4", status: 402, source: "zones", superseded: true)
    surface.failRequest(
      url: "https://tiles.test/zones/1/2/5", status: 404, source: "zones", superseded: true)
    #expect(map.state.isAccessRequired, "a 402 refuses the organization, whatever credential")
    map.close()
    var told: [MapEvent] = []
    for await event in events { told.append(event) }
    #expect(
      told == [
        .accessRefused(status: 401, url: "https://tiles.test/slope/1/2/4"),
        .accessRestored,
        .accessRefused(status: 402, url: "https://tiles.test/zones/1/2/4"),
        .failure(url: "https://tiles.test/zones/1/2/5", status: 404),
      ])
  }

  @Test("the elevation is the Data API's sample, asked for its elevation alone, closed or not")
  func elevation() async throws {
    let answers = Answers()
    let (map, _) = try Self.drawn(exchange: answers)
    map.close()
    #expect(try await map.elevation(at: [6.86, 45.83]) == 1834)
    let sent = await answers.sent
    let body = String(decoding: sent.last?.body ?? Data(), as: UTF8.self)
    #expect(body.contains(#""locations":[[6.86,45.83]]"#), "\(body)")
    #expect(
      body.contains("samples") && body.contains("elevation") && !body.contains("slope"), "\(body)")
  }

  @Test("a label language relabels the base map alone, and again on each style a switch brings in")
  func labelScope() throws {
    let (map, surface) = try Self.drawn()
    surface.baseLabels = [
      .init(id: "place-label", textField: "{name}"), .init(id: "road-shield", textField: "{ref}"),
    ]
    map.addLayer(
      MapLayer(
        id: "waypoint-label", type: .symbol, source: "s", rank: 90,
        layout: ["text-field": "{name}"]))
    map.setLabelLanguage(.fr)
    #expect(surface.relabelled == ["place-label"])
    surface.baseLabels = [.init(id: "water-label", textField: ["get", "name"])]
    surface.loadStyle()
    #expect(surface.relabelled == ["place-label", "water-label"])
  }

  @Test("a closed map is inert: no move, no fit, no query, no projection, no event, no state")
  func closed() async throws {
    let (map, surface) = try Self.drawn()
    let events = map.events()
    map.close()
    let ended = map.state
    try map.jump(to: CameraTarget(zoom: 4))
    try map.fitBounds([6.8, 45.8, 6.95, 45.9])
    map.zoomIn()
    try map.setZoomBounds(min: 2, max: 5)
    map.setLabelLanguage(.de)
    surface.tap(at: [1, 2], position: [6.86, 45.83])
    surface.failRequest(url: "https://tiles.test/x", status: 402, source: nil)
    #expect(map.project([6.86, 45.83]).allSatisfy { $0.isNaN })
    #expect(map.unproject([1, 2]).allSatisfy { $0.isNaN })
    #expect(surface.moves.isEmpty && surface.frames.isEmpty && surface.relabelled.isEmpty)
    #expect(map.state == ended)
    var told = 0
    for await _ in events { told += 1 }
    for await _ in map.events() { told += 1 }
    #expect(told == 0)
    #expect(map.credits.count == 1)
  }

  // MARK: - Content

  /// Contents is an exchange answering the Tile API's catalogue, with two classic overlays and an
  /// enrichment, and each specification, with one source drawing a line `line-` then what it names,
  /// recording the path of every request.
  private actor Contents: HTTPExchange {
    private(set) var paths: [String] = []
    private(set) var queries: [String] = []

    static let catalogue = #"""
      {"data": {
        "elevation": {"id": "e", "tile_size": 512, "url": "https://tiles.test/elevation.json"},
        "itineraries": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
          "content_type": "application/x-protobuf", "id": "i", "locales": {}, "slug": "itineraries", "sources": []},
        "zones": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
          "content_type": "application/x-protobuf", "id": "z", "locales": {}, "slug": "zones", "sources": []},
        "overlays": [
          {"id": "c", "locales": {}, "slug": "conditions", "children": [
            {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "slope", "locales": {}, "slug": "slope",
              "sources": [{"id": "slope", "layers": [{"id": "slope-layer", "key": "slope",
                "layout": null, "paint": null, "source_layer": "slope", "type": "fill",
                "zoom_max": 22, "zoom_min": 14}], "tiles": ["https://tiles.test/slope/{z}/{x}/{y}"],
                "type": "vector", "zoom_max": 14, "zoom_min": 0}]},
            {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "aspect", "locales": {}, "slug": "aspect",
              "sources": [{"id": "aspect", "layers": [{"id": "aspect-layer", "key": "aspect",
                "layout": null, "paint": null, "source_layer": "aspect", "type": "fill",
                "zoom_max": 22, "zoom_min": 0}], "tiles": ["https://tiles.test/aspect/{z}/{x}/{y}"],
                "type": "vector", "zoom_max": 14, "zoom_min": 0}]}]},
          {"id": "e", "locales": {}, "slug": "enrichment", "children": [
            {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "contours", "locales": {},
              "slug": "contours", "sources": [{"id": "contours", "layers": [{"id": "contours-layer",
                "key": "contours", "layout": null, "paint": null, "source_layer": "contours",
                "type": "line", "zoom_max": 22, "zoom_min": 0}],
                "tiles": ["https://tiles.test/contours/{z}/{x}/{y}"], "type": "vector",
                "zoom_max": 14, "zoom_min": 0}]}]}],
        "terrains": []}}
      """#

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      paths.append(request.url.path)
      queries.append(request.url.query ?? "")
      let parts = request.url.pathComponents.filter { $0 != "/" }
      let body: String
      if parts.last == "tile-layers" {
        body = Self.catalogue
      } else {
        let name = parts.count == 4 ? parts[2] : parts[1]
        body = """
          {"data": {"sources": [{"id": "source-\(name)", "layers": [{"id": "line-\(name)",
            "key": "", "layout": null, "paint": null, "source_layer": "itinerary_lines",
            "type": "line", "zoom_max": 22, "zoom_min": 0}],
            "tiles": ["https://tiles.test/\(name)/{z}/{x}/{y}"], "type": "vector",
            "zoom_max": 14, "zoom_min": 0}]}}
          """
      }
      return ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(body.utf8)))
    }
  }

  private static func layerIds(_ map: MapEngine) -> [String] {
    map.state.layers.map(\.id)
  }

  @Test("each kind of content is a slot of its own, drawn by id, switched or cleared")
  func contentSlots() async throws {
    let exchange = Contents()
    let (map, _) = try Self.drawn(exchange: exchange)
    #expect(try await map.setItinerary("a"))
    #expect(try await map.setCollection("c"))
    try await map.setItineraries(true)
    try await map.setItineraries(true)
    try await map.setZones(false)
    #expect(
      Self.layerIds(map) == [
        "line-a", "line-c", "line-itineraries", "line-a__road-access-stripe",
        "line-c__road-access-stripe", "line-itineraries__road-access-stripe",
        "line-a__road-access-icon", "line-c__road-access-icon",
        "line-itineraries__road-access-icon",
      ])
    #expect(
      await exchange.paths == [
        "/v1/itineraries/a/specification", "/v1/collections/c/specification",
        "/v1/itineraries/specification",
      ], "a toggle switched on while it is on reads nothing again")
    #expect(try await map.setItinerary("b"))
    #expect(!Self.layerIds(map).contains("line-a"), "the latest request takes the slot's place")
    #expect(map.state.sources.map(\.id) == ["source-c", "source-itineraries", "source-b"])
    map.clearItinerary()
    map.clearCollection()
    try await map.setItineraries(false)
    #expect(map.state.layers.isEmpty)
    #expect(map.state.sources.isEmpty)
    map.close()
    #expect(try await map.setItinerary("a") == false, "a closed map draws nothing")
    #expect(await exchange.paths.count == 4, "and reads nothing")
  }

  @Test(
    "an itinerary drawn with a fit reads its geometry beside it, and a read that fails draws nothing"
  )
  func itineraryFit() async throws {
    let exchange = Contents()
    let (map, surface) = try Self.drawn(exchange: exchange)
    await #expect(throws: MapError(kind: .numberRefused, name: "maxZoom")) {
      try await map.setItinerary("a", fit: CameraFit(maxZoom: .infinity))
    }
    #expect(await exchange.paths.isEmpty, "a refused fit reads nothing")
    // The exchange answers the itinerary's own read with no itinerary, which fails the call.
    await #expect(throws: (any Error).self) {
      try await map.setItinerary("a", fit: CameraFit())
    }
    #expect(
      Set(await exchange.paths) == ["/v1/itineraries/a/specification", "/v1/itineraries/a"])
    #expect(map.state.layers.isEmpty, "a call that failed drew nothing")
    #expect(surface.frames.isEmpty)
  }

  @Test("a specification drawn under a name replaces what it drew, and keeps its place among keys")
  func specificationsByName() throws {
    let map = MapEngine(client: try Self.client())
    func specification(_ id: String, key: String, sourceLayer: String)
      -> TileSchema.TileSpecification
    {
      TileSchema.TileSpecification(sources: [
        TileSchema.TileSource(
          id: "\(id)-source",
          layers: [
            TileSchema.TileLayer(
              id: id, key: key, layout: nil, paint: nil, source_layer: sourceLayer,
              type: .fill, zoom_max: 22, zoom_min: 0)
          ], tiles: ["https://tiles.test/\(id)/{z}/{x}/{y}"], type: .vector,
          zoom_max: 14, zoom_min: 0)
      ])
    }
    try map.setSpecification(
      specification("relief", key: "hillshade", sourceLayer: "x"), named: "relief")
    try map.setSpecification(
      specification("rain", key: "weather", sourceLayer: "y"), named: "weather")
    try map.setSpecification(
      specification("contours", key: "contours", sourceLayer: "z"), named: "relief")
    #expect(map.specifications == ["relief", "weather"])
    #expect(map.drawnLayerKeys() == ["contours", "weather"])
    #expect(map.state.sources.map(\.id) == ["rain-source", "contours-source"])

    var refused = specification("slope", key: "slope", sourceLayer: "s")
    refused.sources[0].type = TileSchema.TileSourceType(rawValue: "geojson")
    let before = map.state
    #expect(throws: MapError(kind: .typeRefused, name: "geojson")) {
      try map.setSpecification(refused, named: "relief")
    }
    #expect(map.state == before, "a refused specification draws nothing")

    map.setLayerVisibility("rain", visible: false)
    map.removeSpecification(named: "weather")
    #expect(map.isLayerVisible("rain"), "a clear forgets the app's word on its layers")
    map.clearSpecifications()
    #expect(map.specifications.isEmpty)
    #expect(map.state.layers.isEmpty)
  }

  @Test("the app's word on a layer is kept by its id, before it is drawn and across a switch")
  func visibility() throws {
    let map = MapEngine(client: try Self.client())
    map.setLayerVisibility("route", visible: false)
    #expect(!map.isLayerVisible("route"))
    map.addLayer(Self.line)
    #expect(map.state.layers.first?.isHidden == true, "born hidden")
    map.setStyle(try Self.url("https://example.com/other.json"))
    #expect(map.state.layers.first?.isHidden == true, "across a base-map switch")
    map.setLayerVisibility("route", visible: true)
    #expect(map.state.layers.first?.layout["visibility"] == "visible")
    map.setLayerVisibility("route", visible: false)
    map.removeLayer("route")
    #expect(map.isLayerVisible("route"), "a layer taken off forgets the word")
    #expect(map.isLayerVisible("caf\u{E9}"))
    map.setLayerVisibility("cafe\u{301}", visible: false)
    #expect(map.isLayerVisible("caf\u{E9}"), "an id is matched by its scalars")
  }

  @Test("a concept is named by its key, listed once, and shown while none of its layers is hidden")
  func keys() throws {
    let map = MapEngine(client: try Self.client())
    func layer(_ id: String, key: String, sourceLayer: String, type: TileSchema.TileLayerType)
      -> TileSchema.TileLayer
    {
      TileSchema.TileLayer(
        id: id, key: key, layout: nil, paint: nil, source_layer: sourceLayer, type: type,
        zoom_max: 22, zoom_min: 0)
    }
    try map.setSpecification(
      TileSchema.TileSpecification(sources: [
        TileSchema.TileSource(
          id: "pois",
          layers: [
            layer(
              "food-icon", key: "poi_food", sourceLayer: "poi_food", type: .symbol),
            layer(
              "food-label", key: "poi_food", sourceLayer: "poi_food", type: .symbol),
            layer("relief", key: "hillshade", sourceLayer: "x", type: .hillshade),
            layer("unnamed", key: "", sourceLayer: "parking", type: .symbol),
          ], tiles: ["https://tiles.test/pois/{z}/{x}/{y}"], type: .vector,
          zoom_max: 14, zoom_min: 0)
      ]), named: "pois")

    #expect(map.drawnLayerKeys() == ["poi_food", "hillshade"], "the empty key names no concept")
    #expect(map.drawnLayerKeys(rank: LayerRank.poi.rank) == ["poi_food"])
    #expect(map.drawnLayerKeys(rank: LayerRank.hillshade.rank) == ["hillshade"])
    #expect(map.drawnLayerKeys(rank: LayerRank.zone.rank).isEmpty)
    #expect(map.layerIds(forKey: "poi_food") == ["food-icon", "food-label"])
    #expect(map.layerIds(forKey: "contours").isEmpty)
    #expect(map.isKeyVisible("contours"), "a key that draws nothing reads as shown")
    map.setLayerVisibility("food-label", visible: false)
    #expect(!map.isKeyVisible("poi_food"))
    map.setKeyVisibility("poi_food", visible: true)
    #expect(map.isKeyVisible("poi_food"))
    map.setKeyVisibility("poi_food", visible: false)
    #expect(
      map.state.layers.filter { $0.key == "poi_food" }.allSatisfy { $0.isHidden },
      "every layer of the concept is hidden")
  }

  @Test("the restricted stretches are shown until the app hides them, and a word by id stands")
  func accessRestrictions() async throws {
    let (map, _) = try Self.drawn(exchange: Contents())
    #expect(map.isAccessRestrictionsVisible)
    try await map.setItinerary("a")
    map.setAccessRestrictionsVisibility(false)
    #expect(
      map.state.layers.filter { $0.id.contains("__road-access-") }.allSatisfy { $0.isHidden })
    try await map.setCollection("c")
    #expect(
      map.state.layers.first { $0.id == "line-c__road-access-icon" }?.isHidden == true,
      "an itinerary drawn after is born hidden")
    map.setLayerVisibility("line-a__road-access-stripe", visible: false)
    map.setAccessRestrictionsVisibility(true)
    #expect(map.state.layers.first { $0.id == "line-a__road-access-stripe" }?.isHidden == true)
    #expect(map.state.layers.first { $0.id == "line-a__road-access-icon" }?.isHidden == false)
    map.setLayerVisibility("line-c__road-access-stripe", visible: true)
    map.setAccessRestrictionsVisibility(false)
    map.setLayerVisibility("line-c__road-access-stripe", visible: true)
    #expect(
      map.state.layers.first { $0.id == "line-c__road-access-stripe" }?.isHidden == true,
      "a stretch is drawn only while the stretches are shown")
  }

  @Test("a classic overlay replaces the one drawn, enrichments stack, each looked up by its kind")
  func overlays() async throws {
    let exchange = Contents()
    let (map, surface) = try Self.drawn(exchange: exchange)
    try await map.setOverlay("slope")
    #expect(Self.layerIds(map) == ["slope-layer"])
    #expect(
      surface.moves.last
        == ScriptedMapSurface.Move(
          target: CameraTarget(zoom: 14), motion: .ease(duration: .milliseconds(250))),
      "the camera eases into the zooms the overlay paints across")
    try await map.setOverlay("aspect")
    try await map.addEnrichment("contours")
    try await map.addEnrichment("contours")
    #expect(Self.layerIds(map) == ["aspect-layer", "contours-layer"])
    #expect(map.enrichments == ["contours"])
    await #expect(throws: MapError(kind: .kindMismatch, name: "contours")) {
      try await map.setOverlay("contours")
    }
    await #expect(throws: MapError(kind: .kindMismatch, name: "slope")) {
      try await map.addEnrichment("slope")
    }
    await #expect(throws: MapError(kind: .overlayNotFound, name: "snow")) {
      try await map.addEnrichment("snow")
    }
    #expect(Self.layerIds(map) == ["aspect-layer", "contours-layer"], "a refusal draws nothing")
    map.clearOverlay()
    map.clearEnrichments()
    #expect(map.state.layers.isEmpty)
    #expect(map.enrichments.isEmpty)
    #expect(await exchange.paths == ["/v1/tile-layers"], "the catalogue is read once")
  }

  // MARK: - The instant pinned

  /// Stamped is an exchange answering the Tile API's catalogue with a classic overlay the server
  /// stamps, `snow-depth`, one it does not, `slope`, and an enrichment it stamps, `radar`.
  private struct Stamped: HTTPExchange {
    static let catalogue = #"""
      {"data": {
        "elevation": {"id": "e", "tile_size": 512, "url": "https://tiles.test/elevation.json"},
        "itineraries": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
          "content_type": "application/x-protobuf", "id": "i", "locales": {}, "slug": "itineraries", "sources": []},
        "zones": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
          "content_type": "application/x-protobuf", "id": "z", "locales": {}, "slug": "zones", "sources": []},
        "overlays": [
          {"id": "c", "locales": {}, "slug": "conditions", "children": [
            {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": true}},
              "content_type": "application/x-protobuf", "id": "snow-depth", "locales": {},
              "slug": "snow-depth", "sources": [{"id": "snow-depth", "layers": [{"id": "snow-layer",
                "key": "snow", "layout": null, "paint": null, "source_layer": "snow", "type": "fill",
                "zoom_max": 22, "zoom_min": 0}], "tiles": ["https://tiles.test/snow/{z}/{x}/{y}?key=k",
                "https://tiles.test/snow-b/{z}/{x}/{y}"], "type": "vector", "zoom_max": 14, "zoom_min": 0}]},
            {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "slope", "locales": {}, "slug": "slope",
              "sources": [{"id": "slope", "layers": [{"id": "slope-layer", "key": "slope",
                "layout": null, "paint": null, "source_layer": "slope", "type": "fill",
                "zoom_max": 22, "zoom_min": 0}], "tiles": ["https://tiles.test/slope/{z}/{x}/{y}"],
                "type": "vector", "zoom_max": 14, "zoom_min": 0}]}]},
          {"id": "e", "locales": {}, "slug": "enrichment", "children": [
            {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": true}},
              "content_type": "application/x-protobuf", "id": "radar", "locales": {},
              "slug": "radar", "sources": [{"id": "radar", "layers": [{"id": "radar-layer",
                "key": "radar", "layout": null, "paint": null, "source_layer": "radar",
                "type": "fill", "zoom_max": 22, "zoom_min": 0}],
                "tiles": ["https://tiles.test/radar/{z}/{x}/{y}"], "type": "vector",
                "zoom_max": 14, "zoom_min": 0}]}]}],
        "terrains": []}}
      """#

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(Self.catalogue.utf8)))
    }
  }

  /// noon is 2026-03-14T09:00:00Z, which a stamped address writes as `stamp` does.
  private static let noon = Date(timeIntervalSince1970: 1_773_478_800)
  private static let stamp = "timestamp=2026-03-14T09%3A00%3A00.000Z"

  /// tiles is the addresses the state hands the renderer for the source `id`.
  private static func tiles(_ map: MapEngine, source id: String) -> [String] {
    switch map.state.sources.first(where: { $0.id == id })?.kind {
    case .vector(let tiles, _)?: tiles
    default: []
    }
  }

  @Test("a pin asks the overlay drawn for its instant in place, and none draws its own addresses")
  func instantStamps() async throws {
    let (map, _) = try Self.drawn(exchange: Stamped())
    try await map.setOverlay("snow-depth")
    let own = [
      "https://tiles.test/snow/{z}/{x}/{y}?key=k", "https://tiles.test/snow-b/{z}/{x}/{y}",
    ]
    #expect(Self.tiles(map, source: "snow-depth") == own)
    let layers = map.state.layers

    map.setInstant(Self.noon)
    #expect(map.instant == Self.noon)
    #expect(
      Self.tiles(map, source: "snow-depth") == [
        "https://tiles.test/snow/{z}/{x}/{y}?key=k&\(Self.stamp)",
        "https://tiles.test/snow-b/{z}/{x}/{y}?\(Self.stamp)",
      ])
    #expect(map.state.layers == layers, "the overlay is asked again, never drawn anew")

    map.setInstant(nil)
    #expect(map.instant == nil)
    #expect(Self.tiles(map, source: "snow-depth") == own)
  }

  @Test("an overlay drawn under a pin is drawn for it, never an enrichment or one not stamped")
  func instantDrawsLater() async throws {
    let (map, _) = try Self.drawn(exchange: Stamped())
    map.setInstant(Self.noon)
    try await map.setOverlay("slope")
    try await map.addEnrichment("radar")
    #expect(Self.tiles(map, source: "slope") == ["https://tiles.test/slope/{z}/{x}/{y}"])
    #expect(Self.tiles(map, source: "radar") == ["https://tiles.test/radar/{z}/{x}/{y}"])

    try await map.setOverlay("snow-depth")
    #expect(Self.tiles(map, source: "snow-depth").allSatisfy { $0.hasSuffix(Self.stamp) })
    #expect(Self.tiles(map, source: "radar") == ["https://tiles.test/radar/{z}/{x}/{y}"])
  }

  @Test("a pin outlives the overlay drawn, and a base-map switch keeps the addresses asked for")
  func instantStands() async throws {
    let (map, surface) = try Self.drawn(exchange: Stamped())
    try await map.setOverlay("snow-depth")
    map.setInstant(Self.noon)
    map.clearOverlay()
    #expect(map.instant == Self.noon)
    #expect(Self.tiles(map, source: "snow-depth").isEmpty)

    try await map.setOverlay("snow-depth")
    map.setStyle(try Self.url("https://tiles.test/v1/terrains/winter/light/style"))
    surface.loadStyle()
    #expect(Self.tiles(map, source: "snow-depth").allSatisfy { $0.hasSuffix(Self.stamp) })
    #expect(Self.tiles(map, source: "snow-depth").count == 2)
  }

  @Test("a pin naming no instant pins none, and a closed map is inert")
  func instantRefused() async throws {
    let (map, _) = try Self.drawn(exchange: Stamped())
    try await map.setOverlay("snow-depth")
    map.setInstant(Self.noon)
    map.setInstant(Date(timeIntervalSince1970: .nan))
    #expect(map.instant == nil)
    #expect(!Self.tiles(map, source: "snow-depth").contains { $0.contains("timestamp") })
    map.setInstant(Date(timeIntervalSince1970: 9e12))
    #expect(map.instant == nil, "past the range every SDK holds a time to")

    map.close()
    map.setInstant(Self.noon)
    #expect(map.instant == nil)
  }

  @Test("a layers selection's pin is the map's")
  func instantSelected() async throws {
    let (map, _) = try Self.drawn(exchange: Stamped())
    let selection = LayersSelectionEngine(map: map)
    await Self.settled()
    selection.setOverlay("snow-depth")
    selection.setInstant(Self.noon)
    await Self.settled()

    #expect(map.instant == Self.noon)
    #expect(Self.tiles(map, source: "snow-depth").allSatisfy { $0.hasSuffix(Self.stamp) })
    #expect(selection.state.refusal == nil)
    selection.close()
  }

  @Test("the catalogue is read once for the scope and told, and moving the scope drops it")
  func catalogue() async throws {
    let exchange = Contents()
    let (map, _) = try Self.drawn(exchange: exchange)
    let events = map.events()
    #expect(map.layersManifest == nil)
    let first = try await map.loadLayers()
    let again = try await map.loadLayers()
    #expect(first == again)
    #expect(map.layersManifest == first)
    map.setLayersOrganization("")
    map.setLayersOrganization(nil)
    #expect(map.layersManifest == first, "naming the scope held changes nothing")
    map.setLayersOrganization("org-1")
    #expect(map.layersManifest == nil)
    _ = try await map.loadLayers()
    #expect(await exchange.queries == ["", "organization_id=org-1"])
    map.close()
    #expect(try await map.loadLayers() == first, "a closed map answers the catalogue it held")
    var told: [MapEvent] = []
    for await event in events { told.append(event) }
    #expect(told == [.layersChange(first), .layersChange(nil), .layersChange(first)])

    let (closed, _) = try Self.drawn(exchange: exchange)
    closed.close()
    await #expect(throws: MapError(kind: .closed, name: "loadLayers")) {
      _ = try await closed.loadLayers()
    }
    #expect(await exchange.paths.count == 2, "a closed map reads nothing more")
  }

  @Test("a marker carries its glyph, an edit changes it, and a place of four numbers is refused")
  func markerGlyph() throws {
    let map = MapEngine(client: try Self.client())
    try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83], glyph: "hut"))

    try map.editMarker("hut", glyph: "mountain")

    #expect(
      map.state.markers == [MapMarker(id: "hut", position: [6.86, 45.83], glyph: "mountain")])
    #expect(throws: MapError(kind: .positionRefused, name: "col")) {
      try map.addMarker(MapMarker(id: "col", position: [6.86, 45.83, 2_000, 1]))
    }
  }

  @Test("a geometry slot draws what it holds in its colour, an edit keeps what it leaves nil")
  func geometrySlots() throws {
    let map = MapEngine(client: try Self.client())
    let line = GeoJSONGeometry.lineString(
      GeoJSONLineString(coordinates: [[6.86, 45.83], [6.87, 45.84]]))

    map.setGeometry(line, in: .preview)
    #expect(map.geometry(in: .preview) == SlotGeometry(geometry: line, color: "#2b8a3e"))
    #expect(Self.layerIds(map) == ["mountaya-preview-casing", "mountaya-preview-line"])
    #expect(map.state.sources.map(\.id) == ["mountaya-preview"])

    map.editGeometry(in: .preview, color: "#123456")
    #expect(map.geometry(in: .preview) == SlotGeometry(geometry: line, color: "#123456"))
    #expect(map.state.layers.last?.paint["line-color"] == "#123456")

    map.setGeometry(.point(GeoJSONPoint(coordinates: [6.86, 45.83])), in: .highlight)
    #expect(
      Self.layerIds(map) == [
        "mountaya-preview-casing", "mountaya-preview-line", "mountaya-highlight-casing",
        "mountaya-highlight-line", "mountaya-highlight-point",
      ], "the highlight draws at the chrome band, above the preview")
  }

  @Test("a geometry slot holding none draws nothing, and a clear gives the slot its own colour")
  func geometrySlotsCleared() throws {
    let map = MapEngine(client: try Self.client())
    let point = GeoJSONGeometry.point(GeoJSONPoint(coordinates: [6.86, 45.83]))
    map.setGeometry(point, in: .preview)
    map.setGeometry(point, in: .highlight, color: "#654321")

    map.setGeometry(nil, in: .preview, color: "#abcdef")
    #expect(map.geometry(in: .preview) == SlotGeometry(geometry: nil, color: "#abcdef"))
    #expect(map.state.sources.map(\.id) == ["mountaya-highlight"])

    map.clearGeometry(in: .highlight)
    #expect(map.geometry(in: .highlight) == SlotGeometry(geometry: nil, color: "#f59f00"))
    #expect(map.state.layers.isEmpty)
    #expect(map.state.sources.isEmpty)
    #expect(map.geometry(in: .emphasis) == SlotGeometry(geometry: nil, color: "#e9501e"))
  }

  @Test("a picked result is drawn above everything else in the accent, one at a time")
  func searchHighlight() throws {
    let map = MapEngine(client: try Self.client())
    map.setGeometry(.point(GeoJSONPoint(coordinates: [6.86, 45.83])), in: .highlight)

    map.setSearchHighlight(.place(point: [6.86, 45.83]))
    #expect(map.state.sources.map(\.id) == ["mountaya-highlight", "mountaya-search-highlight"])
    #expect(map.state.layers.last?.id == "mountaya-search-highlight-place")
    #expect(map.state.layers.last?.rank == LayerRank.chrome.rank)
    #expect(
      map.state.layers.last?.layout["icon-image"] == "poi-icon-point-1c7ed6",
      "the standard accent where none is handed")

    map.setSearchHighlight(
      .way(anchor: [6.85, 45.82], bounds: nil, coordinates: [[6.8, 45.8], [6.9, 45.85]]),
      accent: HexColor(hex: "#e8590c"))
    #expect(
      Self.layerIds(map).filter { $0.hasPrefix("mountaya-search-highlight") } == [
        "mountaya-search-highlight-halo", "mountaya-search-highlight-casing",
        "mountaya-search-highlight-line", "mountaya-search-highlight-endpoints",
      ], "the latest call replaces the one before")
    #expect(map.geometry(in: .highlight).geometry != nil, "the geometry slot is left alone")

    map.setSearchHighlight(nil)
    #expect(map.state.sources.map(\.id) == ["mountaya-highlight"])
    #expect(!Self.layerIds(map).contains { $0.hasPrefix("mountaya-search-highlight") })
  }

  @Test("a picked result is kept across a base-map switch, and a closed map draws none")
  func searchHighlightKept() throws {
    let map = MapEngine(
      client: try Self.client(), style: try Self.url("https://tiles.test/a/style"))
    map.setSearchHighlight(.poi(point: [6.86, 45.83], category: .hut))
    let drawn = map.state.layers

    map.setStyle(try Self.url("https://tiles.test/b/style"))
    #expect(map.state.layers == drawn)
    #expect(map.state.sources.map(\.id) == ["mountaya-search-highlight"])

    let glyphless = MapEngine(
      client: try Self.client(),
      glyphs: try #require(
        GlyphSet(name: "no-point", paint: .stroke, markup: ["map-pin": #"<path d="M0 0h1"/>"#])))
    glyphless.setSearchHighlight(.place(point: [6.86, 45.83]))
    #expect(glyphless.state.layers.first?.layout["icon-image"] == "poi-icon-map-pin-1c7ed6")

    map.close()
    map.setSearchHighlight(nil)
    #expect(map.state.layers == drawn, "a closed map is inert")
    let closed = MapEngine(client: try Self.client())
    closed.close()
    closed.setSearchHighlight(.place(point: [6.86, 45.83]))
    #expect(closed.state.layers.isEmpty)
  }

  /// Queries answers the Data API: a query sent with its persisted digest alone is refused, as the
  /// protocol asks, and one sending its full document is recorded and answered, or held until the
  /// test lets it answer. Isochrones answer a band per value of the query's `range`, suggestions
  /// three candidates. A held query fails with `CancellationError` once its task is cancelled.
  @MainActor
  private final class Queries: HTTPExchange {
    let holding: Bool
    private(set) var kinds: [String] = []
    private(set) var inputs: [[String: Any]] = []
    private(set) var cancelled: [Int] = []
    private var held: [Int: CheckedContinuation<ExchangeResponse, any Error>] = [:]
    private var arrivals: [(count: Int, waiter: CheckedContinuation<Void, Never>)] = []

    init(holding: Bool = false) {
      self.holding = holding
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      let body = try JSONSerialization.jsonObject(with: request.body ?? Data()) as? [String: Any]
      guard let document = body?["query"] as? String else {
        return Self.answer(
          #"{"errors": [{"message": "PersistedQueryNotFound", "extensions": {"code": "PERSISTED_QUERY_NOT_FOUND"}}]}"#
        )
      }
      let words = document.split { !$0.isLetter }
      let kind = words.firstIndex(of: "query").flatMap { words.dropFirst($0 + 1).first }
      let input = (body?["variables"] as? [String: Any])?["input"] as? [String: Any] ?? [:]
      let index = kinds.count
      kinds.append(kind.map { $0.lowercased() } ?? "")
      inputs.append(input)
      let ranges = (input["range"] as? [Double]) ?? []
      let answer = Self.answered(kinds[index], ranges: ranges)
      for arrival in arrivals where arrival.count <= kinds.count {
        arrival.waiter.resume()
      }
      arrivals.removeAll { $0.count <= kinds.count }
      guard holding else { return Self.answer(answer) }
      return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          held[index] = continuation
        }
      } onCancel: {
        Task { @MainActor in self.cancel(index) }
      }
    }

    /// arrived waits until `count` queries have arrived.
    func arrived(_ count: Int) async {
      guard kinds.count < count else { return }
      await withCheckedContinuation { arrivals.append((count, $0)) }
    }

    private func cancel(_ index: Int) {
      cancelled.append(index)
      held.removeValue(forKey: index)?.resume(throwing: CancellationError())
    }

    private static func answered(_ kind: String, ranges: [Double]) -> String {
      let route =
        #"{"distance": 1000, "duration": 600, "geometry": {"coordinates": [[6.86, 45.83], [6.9, 45.9]], "type": "LineString"}}"#
      switch kind {
      case "isochrones":
        let bands = ranges.map { value in
          #"{"center": [6.86, 45.83], "geometry": {"coordinates": [[[6.85, 45.82], [6.87, 45.82], [6.87, 45.84], [6.85, 45.82]]], "type": "Polygon"}, "value": \#(value)}"#
        }
        return #"{"data": {"isochrones": {"isochrones": [\#(bands.joined(separator: ","))]}}}"#
      default:
        return #"{"data": {"suggestions": {"routes": [\#(route), \#(route), \#(route)]}}}"#
      }
    }

    private static func answer(_ text: String) -> ExchangeResponse {
      ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(text.utf8)))
    }
  }

  /// marks is what each feature the result `id` draws is marked with: whether a suggested
  /// candidate is the one chosen, or an isochrone band's value.
  private static func marks(_ map: MapEngine, result id: String, property: String) -> [JSONValue?] {
    guard
      case .geoJson(let drawn)? = map.state.sources.first(where: { $0.id == "mountaya-\(id)" })?
        .kind
    else { return [] }
    return drawn.features.map { $0.properties[property] }
  }

  private static let suggestionsInput = DataSchema.SuggestionsInput(
    activity: .hikingAndTrail, candidates: 3, distance: 10_000, start: [6.86, 45.83])

  private static let isochronesInput = DataSchema.IsochronesInput(
    activity: .hikingAndTrail, locations: [[6.86, 45.83]], range: [600, 1_200], rangeType: .time)

  @Test("a result handed over is drawn under an id of its own, removed by it and cleared by kind")
  func analysesDrawn() async throws {
    let map = MapEngine(client: try Self.client())
    let band = try JSONDecoder().decode(
      DataSchema.Isochrone.self,
      from: Data(
        #"{"value": 600, "geometry": {"coordinates": [[[6.85, 45.82], [6.87, 45.82], [6.87, 45.84], [6.85, 45.82]]], "type": "Polygon"}}"#
          .utf8))
    let reach = DataSchema.IsochronesResult { $0.isochrones = [band] }
    let found = DataSchema.GeocodeResult {
      $0.places = [
        DataSchema.Place { $0.point = [6.86, 45.83] }, DataSchema.Place { $0.name = "Nowhere" },
      ]
    }

    let first = try await map.addIsochrones(reach)
    let second = try await map.addIsochrones(reach)
    let places = try await map.addPlaces(found)

    #expect(first.id == "analysis:isochrones:0")
    #expect(second.id == "analysis:isochrones:1")
    #expect(places.id == "analysis:places:2")
    #expect(
      Self.marks(map, result: places.id, property: "mtyaIndex") == [0],
      "a place that names no point draws nothing")
    #expect(
      map.state.layers.filter { $0.source == "mountaya-\(first.id)" }.map(\.rank) == [40, 40])
    map.removeAnalysis(first.id)
    #expect(map.state.sources.map(\.id) == ["mountaya-\(second.id)", "mountaya-\(places.id)"])
    map.clearIsochrones()
    #expect(map.state.sources.map(\.id) == ["mountaya-\(places.id)"])
    try await map.setPointsOfInterest(DataSchema.PoisResult { $0.pois = [] })
    #expect(map.state.sources.last?.id == "mountaya-analysis:pois")
    map.clearPointsOfInterest()
    map.clearPlaces()
    #expect(map.state.sources.isEmpty)
    #expect(map.state.layers.isEmpty)
  }

  @Test("an edit asks again with its patch, and a restyle redraws the result held, asking nothing")
  func analysisEdit() async throws {
    let exchange = Queries()
    let map = MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"), exchange: exchange))
    let suggested = try await map.addSuggestions(Self.suggestionsInput)
    #expect(suggested.id == "analysis:suggestions:0")
    #expect(Self.marks(map, result: suggested.id, property: "chosen") == [true, false, false])

    _ = try await map.editSuggestions(suggested.id, chosen: 2)
    #expect(exchange.kinds == ["suggestions"], "a restyle asks nothing")
    #expect(Self.marks(map, result: suggested.id, property: "chosen") == [false, false, true])

    _ = try await map.editSuggestions(suggested.id, patch: { $0.distance = 20_000 })
    #expect(exchange.kinds == ["suggestions", "suggestions"])
    #expect(exchange.inputs.last?["distance"] as? Double == 20_000)
    #expect(
      Self.marks(map, result: suggested.id, property: "chosen") == [false, false, true],
      "the options are kept")

    let reach = try await map.addIsochrones(Self.isochronesInput)
    #expect(Self.marks(map, result: reach.id, property: "value") == [600, 1_200])
    _ = try await map.editIsochrones(reach.id, patch: { $0.range = [300] })
    #expect(Self.marks(map, result: reach.id, property: "value") == [300])
  }

  @Test("an edit of no result, of another kind's, or asking again of one handed over is refused")
  func analysisEditRefused() async throws {
    let map = MapEngine(client: try Self.client())
    let handed = try await map.addSuggestions(DataSchema.SuggestionsResult { $0.routes = [] })

    await #expect(throws: MapError(kind: .kindMismatch, name: handed.id)) {
      try await map.editIsochrones(handed.id)
    }
    await #expect(throws: MapError(kind: .analysisNotFound, name: "analysis:places:9")) {
      try await map.editPlaces("analysis:places:9")
    }
    await #expect(throws: MapError(kind: .noInput, name: handed.id)) {
      try await map.editSuggestions(handed.id, patch: { $0.distance = 1 })
    }
    _ = try await map.editSuggestions(handed.id, chosen: 1)
  }

  @Test("a removal or a clear cancels the query its result has out, and the call is cancelled")
  func analysisCancelled() async throws {
    let exchange = Queries(holding: true)
    let map = MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_test_a", sessionToken: "sess_a"), exchange: exchange))
    let input = Self.isochronesInput

    let first = Task { try await map.addIsochrones(input) }
    await exchange.arrived(1)
    map.removeAnalysis("analysis:isochrones:0")
    await #expect(throws: CancellationError.self) { try await first.value }
    #expect(exchange.cancelled == [0])

    let second = Task { try await map.addIsochrones(input) }
    await exchange.arrived(2)
    map.clearIsochrones()
    await #expect(throws: CancellationError.self) { try await second.value }
    #expect(exchange.cancelled == [0, 1])
    #expect(map.state.sources.isEmpty)
  }

  @Test("a closed map still answers a result, and draws and holds nothing")
  func analysisClosed() async throws {
    let map = MapEngine(client: try Self.client())
    map.close()

    let handle = try await map.addPlaces(DataSchema.GeocodeResult { $0.places = [] })

    #expect(handle.id == "analysis:places:0")
    await #expect(throws: MapError(kind: .analysisNotFound, name: handle.id)) {
      try await map.editPlaces(handle.id)
    }
    map.setGeometry(.point(GeoJSONPoint(coordinates: [6.86, 45.83])), in: .preview)
    #expect(map.geometry(in: .preview).geometry == nil)
  }

  @Test(
    "a client holding no publishable key reads no organization and never throws, and a closed map with a key refuses"
  )
  func organizationWithoutKey() async throws {
    let shared = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Catalogue()))
    #expect(try await shared.loadOrganization() == nil)
    #expect(shared.organizationRead == .noKey)
    #expect(shared.organization == nil)
    shared.close()
    #expect(try await shared.loadOrganization() == nil, "a closed map holding no key answers nil")

    let map = MapEngine(client: try Self.client())
    #expect(map.organizationRead == .waiting)
    map.close()
    await #expect(throws: MapError(kind: .closed, name: "loadOrganization")) {
      try await map.loadOrganization()
    }
  }

  @Test("a long press opens the readout where it fell, and a tap or a camera move closes it")
  func readout() throws {
    let (map, surface) = try Self.drawn()
    surface.longTap(at: [10, 20], position: [6.86, 45.83])
    #expect(map.readout?.position == [6.86, 45.83])
    #expect(map.readout?.point == [10, 20])

    surface.tap(at: [10, 20], position: [6.86, 45.83])
    #expect(map.readout == nil)

    surface.longTap(at: [10, 20], position: [6.86, 45.83])
    try map.jump(to: CameraTarget(zoom: 13))
    #expect(map.readout == nil)

    map.isReadoutOn = false
    surface.longTap(at: [10, 20], position: [6.86, 45.83])
    #expect(map.readout == nil)
  }

  @Test("a readout's point of interest reads its tile's subclass, else its class")
  func readoutCategory() throws {
    let (map, surface) = try Self.drawn()
    map.addLayer(MapLayer(id: "hut", type: .symbol, source: "s", rank: LayerRank.poi.rank))
    surface.rendered = [
      QueriedFeature(
        properties: ["name": "Refuge", "class": "lodging", "subclass": "alpine_hut"],
        geometry: Self.pointGeometry, layer: "hut")
    ]
    surface.longTap(at: [10, 20], position: [6.86, 45.83])
    #expect(map.readout?.facts.poi?.name == "Refuge")
    #expect(map.readout?.facts.poi?.category == "alpine_hut")

    surface.rendered = [
      QueriedFeature(
        properties: ["name": "Lac", "class": "water", "subclass": ""],
        geometry: Self.pointGeometry, layer: "hut")
    ]
    surface.longTap(at: [10, 20], position: [6.86, 45.83])
    #expect(map.readout?.facts.poi?.category == "water")
  }

  @Test(
    "a readout's zone reads its times to the whole second, a time as text none, and its band the classic overlay's own"
  )
  func readoutZoneAndBand() async throws {
    let (map, surface) = try Self.drawn(exchange: Contents())
    try await map.setOverlay("aspect")
    try await map.addEnrichment("contours")
    map.addLayer(MapLayer(id: "zone-fill", type: .fill, source: "z", rank: LayerRank.zone.rank))
    surface.rendered = [
      QueriedFeature(
        properties: ["minValue": 1800, "maxValue": 2400], geometry: Self.pointGeometry,
        layer: "contours-layer"),
      QueriedFeature(
        properties: ["name": "no band"], geometry: Self.pointGeometry, layer: "aspect-layer"),
      QueriedFeature(
        properties: ["minValue": 0.2, "maxValue": 0.5], geometry: Self.pointGeometry,
        layer: "aspect-layer"),
      QueriedFeature(
        properties: [
          "name": "Couloir", "description": "Rockfall", "level": "warning",
          "start_at": 1_773_475_200.75, "end_at": "1773590400",
        ],
        geometry: Self.pointGeometry, layer: "zone-fill"),
    ]
    surface.longTap(at: [10, 20], position: [6.86, 45.83])
    let facts = try #require(map.readout?.facts)
    #expect(facts.zone?.name == "Couloir" && facts.zone?.description == "Rockfall")
    #expect(facts.zone?.level == .warning)
    #expect(facts.zone?.startAt == 1_773_475_200, "truncated to the whole second")
    #expect(facts.zone?.endAt == nil, "a time written as a string is none")
    #expect(facts.band?.min == 0.2 && facts.band?.max == 0.5, "never another layer's feature")

    surface.rendered = [
      QueriedFeature(
        properties: ["level": "info", "start_at": -0.5, "end_at": 1_773_590_400.999],
        geometry: Self.pointGeometry, layer: "zone-fill")
    ]
    surface.longTap(at: [10, 20], position: [6.86, 45.83])
    #expect(map.readout?.facts.zone?.startAt == 0)
    #expect(map.readout?.facts.zone?.endAt == 1_773_590_400)
    #expect(map.readout?.facts.band == nil, "no feature of the overlay states a value")
  }

  @Test("a read asked again after a failure keeps the watermark while it waits")
  func organizationRetryKeepsMark() async throws {
    let lookups = HeldLookups()
    let map = MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_retry"), retry: try RetryPolicy(maxRetries: 0),
        exchange: lookups),
      geolocation: InertGeolocation())
    map.organizations = OrganizationReads()
    #expect(map.organizationRead == .waiting)
    #expect(!map.isWatermarked, "no mark while the first read waits")

    await #expect(throws: MountayaError.self) { try await map.loadOrganization() }
    #expect(map.organizationRead == .failed)
    #expect(map.isWatermarked)

    map.beginOrganizationRead()
    await lookups.waitForHeld()
    #expect(map.organizationRead == .failed, "a map drawn again leaves its failed read failed")
    #expect(map.isWatermarked, "a read asked again never takes the mark off while it waits")
    let retry = Task { try await map.loadOrganization() }
    await Task.yield()
    #expect(map.isWatermarked, "a host's load waiting on it keeps the mark too")

    await lookups.answer()
    #expect(try await retry.value?.white_label == true)
    #expect(map.organizationRead == .answered(whiteLabel: true))
    #expect(!map.isWatermarked)
  }
}

extension MapEngineTests {
  /// HeldLookups refuses the first organization lookup with a 404, and holds every later one until
  /// `answer()` lets it answer an organization holding white label.
  private actor HeldLookups: HTTPExchange {
    private var sent = 0
    private var held: CheckedContinuation<ExchangeResponse, Never>?
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent += 1
      if sent == 1 {
        return ExchangeResponse(
          status: 404, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(Data(#"{"errors": [{"code": "NOT_FOUND", "message": "no"}]}"#.utf8)))
      }
      return await withCheckedContinuation { continuation in
        held = continuation
        let waiting = waiters
        waiters = []
        for waiter in waiting {
          waiter.resume()
        }
      }
    }

    /// waitForHeld returns once a lookup is held.
    func waitForHeld() async {
      guard held == nil else { return }
      await withCheckedContinuation { waiters.append($0) }
    }

    /// answer lets the lookup held answer.
    func answer() {
      held?.resume(
        returning: ExchangeResponse(
          status: 200, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(Data(OrganizationReadsTests.body.utf8))))
      held = nil
    }
  }

  /// Standing is a geolocation whose standing permission reads `permission` and whose fix is
  /// `fix`, as a device does.
  private final class Standing: Geolocation {
    let fix: GeolocationFix
    let standing: GeolocationPermission

    init(_ fix: GeolocationFix, permission: GeolocationPermission) {
      self.fix = fix
      self.standing = permission
    }

    func locate() async -> GeolocationFix { fix }

    func permission() async -> GeolocationPermission { standing }
  }

  /// settled lets every task the main actor holds run, which is how a test waits for a control's
  /// or a selection's answers to land with no clock.
  private static func settled() async {
    for _ in 0..<16 {
      await Task.yield()
    }
  }

  @Test("the map reports the terrain its base map is, and reads a refused permission alone")
  func controlReads() async throws {
    let (map, _) = try Self.drawn()
    #expect(map.terrain == nil)
    try await map.setTerrain()
    #expect(map.terrain == "outdoor")
    #expect(map.terrain == map.state.terrain)

    for (permission, refused) in [
      (GeolocationPermission.denied, true), (.granted, false), (.prompt, false), (.unknown, false),
    ] {
      let (standing, _) = try Self.drawn(
        geolocation: Standing(.refused(.denied), permission: permission))
      #expect(await standing.isLocationRefused() == refused, "\(permission)")
    }
    map.close()
    #expect(await map.isLocationRefused(), "a closed map still reads its geolocation, an inert one")
  }

  @Test("a layers selection drives the map: one classic overlay, stacked enrichments, refusals")
  func layersSelection() async throws {
    let (map, _) = try Self.drawn(exchange: Contents())
    let selection = LayersSelectionEngine(map: map)
    await Self.settled()
    #expect(selection.state.catalogue == map.layersManifest)
    #expect(selection.state.terrain == nil, "the catalogue holds no terrain the map shows")

    selection.setOverlay("slope")
    selection.toggleEnrichment("contours")
    await Self.settled()
    #expect(map.enrichments == ["contours"])
    #expect(Self.layerIds(map).contains("slope-layer"))
    selection.setOverlay("slope")
    await Self.settled()
    #expect(!Self.layerIds(map).contains("slope-layer"), "a second press clears the overlay")

    selection.setOverlay("snow")
    await Self.settled()
    #expect(selection.state.overlay == "snow", "a refused command keeps what was asked")
    #expect(
      (selection.state.refusal as? MapError) == MapError(kind: .overlayNotFound, name: "snow"))
    selection.toggleEnrichment("contours")
    await Self.settled()
    #expect(selection.state.refusal == nil, "a later command that settles ends the refusal")
    #expect(map.enrichments.isEmpty)
    selection.close()
  }

  @Test("a locate control stands over the map: busy until its fix settles, blocked on its word")
  func geolocateControl() async throws {
    let (prompting, _) = try Self.drawn(
      geolocation: Standing(.refused(.denied), permission: .prompt))
    let control = GeolocateControlEngine(map: prompting)
    var failures: [MapError] = []
    await Self.settled()
    control.locate(onError: { error in
      if let refused = error as? MapError { failures.append(refused) }
    })
    #expect(control.state == GeolocateControlState(isBusy: true, isBlocked: false, isLive: true))
    await Self.settled()
    #expect(control.state == GeolocateControlState(isBusy: false, isBlocked: false, isLive: true))
    #expect(failures == [MapError(kind: .fixRefused(.denied), name: "locate")])

    let (refusing, _) = try Self.drawn(
      geolocation: Standing(.refused(.denied), permission: .denied))
    control.configure(map: refusing)
    await Self.settled()
    #expect(control.state == GeolocateControlState(isBusy: false, isBlocked: true, isLive: true))
    control.close()
  }
}

/// The watermark's window and the readout's reads, over exchanges that hold what they are sent.
extension MapEngineTests {
  /// Held holds every request it is sent but the layers catalogue and the elevation source's
  /// TileJSON, which it answers at once, until a test lets one answer; a request whose task is
  /// cancelled while held is withdrawn.
  private actor Held: HTTPExchange {
    private(set) var paths: [String] = []
    private(set) var withdrawn: [Int] = []
    private var waiting: [Int: CheckedContinuation<ExchangeResponse, any Error>] = [:]

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      let path = request.url.path
      if path.hasSuffix("/v1/tile-layers") {
        return Self.answer(
          #"""
          {"data": {"elevation": {"id": "e", "tile_size": 4, "url": "https://tiles.mountaya.com/v1/elevation/tiles.json"},
            "itineraries": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "i", "locales": {}, "slug": "i", "sources": []},
            "zones": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "z", "locales": {}, "slug": "z", "sources": []},
            "overlays": [], "terrains": []}}
          """#)
      }
      if path.hasSuffix("tiles.json") {
        return Self.answer(
          #"{"encoding": "mapbox", "maxzoom": 16, "tiles": ["https://tiles.mountaya.com/v1/elevation/{z}/{x}/{y}"]}"#
        )
      }
      let index = paths.count
      paths.append(path)
      return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { waiting[index] = $0 }
      } onCancel: {
        Task { await self.withdraw(index) }
      }
    }

    /// answer lets the request `index` answer `body`.
    func answer(_ index: Int, body: String) {
      waiting.removeValue(forKey: index)?.resume(returning: Self.answer(body))
    }

    /// held is how many requests wait on an answer.
    var held: Int { waiting.count }

    private func withdraw(_ index: Int) {
      guard let continuation = waiting.removeValue(forKey: index) else { return }
      withdrawn.append(index)
      continuation.resume(throwing: CancellationError())
    }

    private static func answer(_ body: String) -> ExchangeResponse {
      ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(body.utf8)))
    }
  }

  /// until waits, in real time and two seconds at most, for `condition` to hold, and tells whether
  /// it did.
  private static func until(_ condition: () async -> Bool) async -> Bool {
    for _ in 0..<2_000 {
      if await condition() { return true }
      try? await Task.sleep(for: .milliseconds(1))
    }
    return await condition()
  }

  /// whiteLabel is an organization holding white label, as a lookup answers it.
  private static let whiteLabel = OrganizationReadsTests.body

  @Test("a first read past one attempt's budget draws the mark until an answer says white label")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func organizationWindow() async throws {
    let clock = HeldClock()
    let lookups = Held()
    let client = try Mountaya(
      credential: .publishable(key: "pk_window"), retry: try RetryPolicy(maxRetries: 1),
      exchange: lookups, clock: clock)
    #expect(client.organizationLookupBudget == .seconds(35))
    let map = MapEngine(client: client, geolocation: InertGeolocation())
    map.organizations = OrganizationReads()
    map.beginOrganizationRead()
    // The map's window and the attempt's own budget both wait on the client's clock.
    #expect(await Self.until { await lookups.held == 1 && clock.sleepers == 2 })

    clock.advance(by: .milliseconds(34_999))
    await Self.settled()
    #expect(map.organizationRead == .waiting)
    #expect(!map.isWatermarked, "no mark within one attempt's budget")

    clock.advance(by: .milliseconds(1))
    #expect(await Self.until { map.organizationRead == .timedOut })
    #expect(map.isWatermarked, "the mark once the budget has passed, the read still going on")

    // The attempt that ran out is repeated after its wait, and the repeat answers white label.
    #expect(await Self.until { await lookups.withdrawn == [0] })
    #expect(
      await Self.until {
        clock.advance(by: .seconds(1))
        return await lookups.held == 1
      })
    await lookups.answer(1, body: Self.whiteLabel)
    #expect(await Self.until { map.organizationRead == .answered(whiteLabel: true) })
    #expect(!map.isWatermarked, "a later answer of white label takes the mark off")
    map.close()
  }

  @Test("a client naming a longer attempt budget holds the mark off that long")
  func organizationWindowOfTheClient() throws {
    let client = try Mountaya(credential: .publishable(key: "pk_a"), timeout: .seconds(60))
    #expect(client.organizationLookupBudget == .seconds(60))
    #expect(
      try Mountaya(credential: .publishable(key: "pk_a")).organizationLookupBudget == .seconds(35))
  }

  @Test("the frame kept clear is the mark's, measured from the map's safe area, in the window")
  func watermarkKeptClearFrame() throws {
    let map = MapEngine(client: try Self.client())
    #expect(map.watermarkKeptClearFrame == nil, "no view draws the map")
    map.shown(at: ScreenRect(x: 0, y: 0, width: 393, height: 852))
    map.safeAreaShown(PixelPadding(top: 59, right: 0, bottom: 34, left: 0))
    let frame = try #require(map.watermarkKeptClearFrame)
    #expect(frame.x == -4 && frame.y == 55 && frame.width == 180)
    map.shown(at: ScreenRect(x: 20, y: 100, width: 300, height: 400))
    map.safeAreaShown(PixelPadding(0))
    #expect(map.watermarkKeptClearFrame?.x == 16 && map.watermarkKeptClearFrame?.y == 96)
  }

  @Test("a map laid below a header keeps its own frame and safe area, wherever a stack is laid")
  func framesBelowAHeader() throws {
    let map = MapEngine(client: try Self.client())
    #expect(map.safeAreaFrame == nil, "no view draws the map")
    // The map stands 120 points down a window 844 tall, under an app's header, and reaches the
    // window's bottom, past the home indicator.
    map.shown(at: ScreenRect(x: 0, y: 120, width: 390, height: 724))
    map.safeAreaShown(PixelPadding(top: 0, right: 0, bottom: 34, left: 0))
    #expect(map.safeAreaFrame == ScreenRect(x: 0, y: 120, width: 390, height: 690))
    let frame = try #require(map.watermarkKeptClearFrame, "held while the read waits")
    #expect(frame.x == -4 && frame.y == 116, "from the map's own corner, not the window's")
  }

  @Test("a map whose view goes is drawn by no view, unless another view drew it since")
  func unshownAsItsViewGoes() throws {
    let map = MapEngine(client: try Self.client())
    let gone = ScriptedMapSurface(drawing: map)
    let drawing = ScriptedMapSurface(drawing: map)
    let shown = ScreenRect(x: 0, y: 120, width: 390, height: 724)
    map.shown(at: shown)
    map.safeAreaShown(PixelPadding(top: 0, right: 0, bottom: 34, left: 0))
    map.unshown(by: gone)
    #expect(map.shownMap == shown, "another view draws it since the one that went")
    #expect(map.safeAreaFrame != nil && map.watermarkKeptClearFrame != nil)

    map.unshown(by: drawing)
    #expect(map.shownMap == nil)
    #expect(map.safeAreaFrame == nil, "a stack over it keeps to its own space")
    #expect(map.watermarkKeptClearFrame == nil)
    map.shown(at: shown)
    #expect(map.shownMap == shown, "a view drawing it again tells where it stands")
  }

  @Test("the frame kept clear follows the read: held while it waits, gone once it is white label")
  func watermarkKeptClearFrameFollowsTheRead() async throws {
    let lookups = Held()
    let map = MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_kept_clear"), retry: try RetryPolicy(maxRetries: 0),
        exchange: lookups),
      geolocation: InertGeolocation())
    map.organizations = OrganizationReads()
    map.shown(at: ScreenRect(x: 0, y: 0, width: 390, height: 844))
    #expect(map.organizationRead == .waiting)
    #expect(map.watermarkKeptClearFrame != nil, "held while the read waits")

    map.beginOrganizationRead()
    #expect(await Self.until { await lookups.held == 1 })
    await lookups.answer(0, body: Self.whiteLabel)
    #expect(await Self.until { map.organizationRead == .answered(whiteLabel: true) })
    #expect(!isWatermarkKeptClear(map.organizationRead))
    #expect(map.watermarkKeptClearFrame == nil, "released once the read answers white label")
    map.close()
  }

  @Test("a move the reader begins closes the readout at once, and cancels its tile reads")
  func readoutClosedAsTheReaderMoves() async throws {
    let tiles = Held()
    let map = MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_a"), retry: try RetryPolicy(maxRetries: 0),
        exchange: tiles),
      geolocation: InertGeolocation())
    map.cameraMoved(to: CameraPose(center: [6.8652, 45.9237], zoom: 14, pitch: 0, bearing: 0))
    map.longTapped(at: [10, 20], position: [6.8652, 45.9237])
    #expect(await Self.until { await tiles.held == 1 })
    #expect(map.readout != nil)

    map.readerMoveBegan()
    #expect(map.readout == nil, "closed as the move begins, not as it rests")
    #expect(await Self.until { await tiles.withdrawn == [0] }, "its tile read is cancelled")
    map.close()
  }

  @Test("a press's tile reads leave in the order elevationTilesAt answers them")
  func readoutReadsInOrder() async throws {
    let source = ElevationSource(encoding: .mapbox, tileSize: 4, zoom: 16)
    // A point near a corner of its tile, which needs the four tiles around it.
    let position = [6.8665924072265625, 45.92348]
    let wanted = elevationTilesAt(position, source: source).map {
      "/v1/elevation/\($0.z)/\($0.x)/\($0.y)"
    }
    #expect(wanted.count > 1)
    for _ in 0..<20 {
      let tiles = Held()
      let map = MapEngine(
        client: try Mountaya(
          credential: .publishable(key: "pk_a"), retry: try RetryPolicy(maxRetries: 0),
          exchange: tiles),
        geolocation: InertGeolocation())
      map.cameraMoved(to: CameraPose(center: position, zoom: 14, pitch: 0, bearing: 0))
      map.longTapped(at: [10, 20], position: position)
      #expect(await Self.until { await tiles.held == wanted.count })
      #expect(await tiles.paths == wanted)
      map.close()
      #expect(await Self.until { await tiles.held == 0 })
    }
  }
}
