import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo
import Testing

@Suite("ScriptedMapSurface")
@MainActor
struct ScriptedMapSurfaceTests {
  private static func engine() throws -> MapEngine {
    MapEngine(
      client: try Mountaya(credential: .publishable(key: "pk_test_a")),
      geolocation: InertGeolocation())
  }

  private static let point = GeoJSONGeometry.point(GeoJSONPoint(coordinates: [6.86, 45.83]))

  @Test("it records each move and fit the engine hands it, and lands a fit as cameraForBounds does")
  func records() throws {
    let map = try Self.engine()
    let surface = ScriptedMapSurface(drawing: map, canvas: [800, 600])
    try map.ease(to: CameraTarget(zoom: 12, pitch: 20))
    #expect(
      surface.moves == [
        .init(target: CameraTarget(zoom: 12, pitch: 20), motion: .ease(duration: nil))
      ])
    try map.fitBounds(
      [6.8, 45.8, 6.95, 45.9], with: CameraFit(padding: PixelPadding(48), maxZoom: 15))
    #expect(surface.frames.map(\.bounds) == [[6.8, 45.8, 6.95, 45.9]])
    #expect(abs(map.state.camera.zoom - 11.269337026503) < 1e-9)
    #expect(map.state.camera.pitch == 20, "a fit keeps the pitch")
    #expect(map.state.camera.bearing == 0, "a fit faces north")
    #expect(surface.zoomLimits == ZoomBounds(minZoom: 0, maxZoom: 25.5))
  }

  @Test("it answers a query with the features the layers asked about drew, as the test states them")
  func answers() throws {
    let map = try Self.engine()
    let surface = ScriptedMapSurface(drawing: map)
    map.addLayer(MapLayer(id: "line", type: .line, source: "s", rank: 50))
    surface.rendered = [
      QueriedFeature(properties: ["a": 1], geometry: Self.point, layer: "line"),
      QueriedFeature(properties: [:], geometry: Self.point, layer: "base-road"),
    ]
    #expect(map.features(at: [1, 2]).map(\.layer) == ["line"])
    #expect(surface.queries == [["line"]])
    surface.liveLayers = []
    #expect(map.features(at: [1, 2]).isEmpty)
    #expect(surface.queries == [["line"]], "nothing left to ask, nothing asked")
    #expect(map.project([3, 4]) == [3, 4], "a position read as its point")
  }

  @Test("it plays what happens on a canvas, which the engine tells")
  func plays() async throws {
    let map = try Self.engine()
    let surface = ScriptedMapSurface(drawing: map)
    surface.baseLabels = [.init(id: "place-label", textField: "{name}")]
    let events = map.events()
    surface.tap(at: [1, 2], position: [190, 45])
    surface.longTap(at: [1, 2], position: [6, 45])
    surface.hover(at: [1, 2], position: [6, 45])
    surface.drawFrame()
    surface.leave(at: [1, 2], position: [6, 45])
    surface.failRequest(url: "https://tiles.test/a", status: 403, source: nil)
    surface.loadTile(of: "any")
    surface.loadStyle()
    map.close()
    var told: [MapEvent] = []
    for await event in events {
      told.append(event)
    }
    #expect(
      told == [
        .tap(MapTap(position: [-170, 45], point: [1, 2])),
        .longTap(MapTap(position: [6, 45], point: [1, 2])),
        .featureHover(position: [6, 45], features: []),
        .featureHover(position: [6, 45], features: []),
        .accessRefused(status: 403, url: "https://tiles.test/a"),
        .accessRestored,
      ])
    #expect(surface.relabelled == ["place-label"])
  }

  @Test("it plays the document of the base map asked for not arriving, which gives the map back")
  func failsStyle() throws {
    let map = try Self.engine()
    let surface = ScriptedMapSurface(drawing: map)
    let shown = try #require(URL(string: "https://tiles.test/shown.json"))
    let asked = try #require(URL(string: "https://tiles.test/asked.json"))
    map.setStyle(shown)
    surface.loadStyle()
    map.setStyle(asked)
    surface.failStyle()
    #expect(map.state.style == shown)
    map.setStyle(asked)
    surface.loadStyle()
    surface.failStyle()
    #expect(map.state.style == asked, "a style that loaded is the one shown")
  }

  @Test("it reports the base map's sources it is given, which the map credits beside its own")
  func baseSources() throws {
    let map = try Self.engine()
    let surface = ScriptedMapSurface(drawing: map)
    let mountaya = try #require(map.credits.first)
    #expect(map.credits == [mountaya], "none by default")
    surface.baseSources = [
      ScriptedMapSurface.BaseSource(attribution: "OpenStreetMap", isDrawn: true),
      ScriptedMapSurface.BaseSource(attribution: "Satellite", isDrawn: false),
      ScriptedMapSurface.BaseSource(attribution: mountaya, isDrawn: true),
    ]
    #expect(Set(map.credits) == [mountaya, "OpenStreetMap"])
  }
}
