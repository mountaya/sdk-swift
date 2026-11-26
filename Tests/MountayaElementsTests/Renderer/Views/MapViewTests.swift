import MapLibre
import MountayaClient
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements
@testable import MountayaGeo

@Suite("MapView", .serialized)
@MainActor
struct MapViewTests {
  @Test("the view mounts in SwiftUI, draws its engine's style and hands MapLibre's map to onReady")
  func mounts() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_view"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    map.addSource(MapSource(id: "empty", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    map.addLayer(
      MapLayer(
        id: "route", type: .line, source: "empty", rank: LayerRank.itineraryLine.rank))
    var ready: MLNMapView?
    let host = UIHostingController(rootView: MapView(map, onReady: { ready = $0 }))
    let window = MapWindow.showing(host.view)

    #expect(await MapWindow.until { ready != nil })
    let style = try #require(ready?.style)
    #expect(style.layer(withIdentifier: "base-background") != nil)
    #expect(style.layer(withIdentifier: "route") is MLNLineStyleLayer)
    window.isHidden = true
  }

  @Test("the view hands the map the accent the tokens around it read under the scheme in force")
  func tokens() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_view"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    var tokens = ElementTokens.standard
    tokens.accent = ThemeToken(light: HexColor(hex: "#1c7ed6"), dark: HexColor(hex: "#e9501e"))
    var ready: MLNMapView?
    let host = UIHostingController(
      rootView: MapView(map, onReady: { ready = $0 }).mountayaTokens(tokens)
        .environment(\.colorScheme, .dark))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { ready != nil })

    let renderer = try #require(ready?.delegate as? MapRenderer)
    #expect(renderer.accent == HexColor(hex: "#e9501e"), "the token's dark value, the scheme dark")
    host.rootView = MapView(map, onReady: { ready = $0 }).mountayaTokens(tokens)
      .environment(\.colorScheme, .light)
    #expect(await MapWindow.until { renderer.accent == HexColor(hex: "#1c7ed6") })
    window.isHidden = true
  }

  /// SwiftUI publishes no way to state `accessibilityReduceMotion` for a view, so the test reads
  /// the view writing the setting the environment carries, the simulator's, over one stated before.
  @Test("the view tells the engine whether the reader asked for reduced motion")
  func reducedMotion() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_view"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    map.reducesMotion = !UIAccessibility.isReduceMotionEnabled
    let host = UIHostingController(rootView: MapView(map))
    let window = MapWindow.showing(host.view)

    #expect(await MapWindow.until { map.reducesMotion == UIAccessibility.isReduceMotionEnabled })
    window.isHidden = true
  }

  @Test("the view hands the camera at rest to onCameraChange, whoever moved it")
  func cameraChange() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_view"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    var ready: MLNMapView?
    var rested: [CameraPose] = []
    let host = UIHostingController(
      rootView: MapView(
        map, onReady: { ready = $0 }, onTap: { _ in }, onCameraChange: { rested.append($0) }))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { ready != nil })

    try map.jump(to: CameraTarget(center: [7.5, 46.0], zoom: 13, bearing: 0, pitch: 0))

    #expect(await MapWindow.until { rested.contains { abs($0.zoom - 13) < 0.01 } })
    window.isHidden = true
  }

  @Test("the view reads its organization once drawn, and draws its watermark once the read fails")
  func watermark() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_watermark"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    #expect(!map.isWatermarked, "no mark while the read waits")
    let host = UIHostingController(rootView: MapView(map))
    let window = MapWindow.showing(host.view)

    #expect(await MapWindow.until { map.isWatermarked })
    window.isHidden = true
  }

  @Test("a map whose readout is off opens none on a long press")
  func readoutOff() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_view"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    var ready: MLNMapView?
    let host = UIHostingController(
      rootView: MapView(map, readout: false, onReady: { ready = $0 }))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { ready != nil })

    let renderer = try #require(ready?.delegate as? MapRenderer)
    renderer.pressed(at: CGPoint(x: 20, y: 20))
    #expect(map.readout == nil)
    #expect(!map.isReadoutOn)
    window.isHidden = true
  }

  @Test("a view handed another engine draws it, and that engine reads its organization")
  func engineSwapped() async throws {
    _ = StubTileAPI.installed
    func engine(_ key: String) throws -> MapEngine {
      MapEngine(
        client: try Mountaya(
          credential: .publishable(key: key),
          baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
          retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline()),
        style: StubTileAPI.styleUrl)
    }
    let first = try engine("pk_test_swap_first")
    let second = try engine("pk_test_swap_second")
    var ready: [MLNMapView] = []
    let host = UIHostingController(rootView: MapView(first, onReady: { ready.append($0) }))
    let window = MapWindow.showing(host.view)
    // An offline read fails, which draws the mark.
    #expect(await MapWindow.until { first.isWatermarked })
    #expect(!second.isWatermarked, "an engine no view draws reads nothing")
    #expect(await MapWindow.until { first.shownMap != nil })

    host.rootView = MapView(second, onReady: { ready.append($0) })
    #expect(await MapWindow.until { second.isWatermarked }, "the engine handed reads its own")
    #expect(await MapWindow.until { ready.count == 2 }, "and is drawn on a canvas of its own")
    #expect(ready.last?.delegate.map { ($0 as? MapRenderer)?.engine === second } == true)
    #expect(await MapWindow.until { second.shownMap != nil }, "it is told where it stands")
    #expect(await MapWindow.until { first.shownMap == nil }, "the one before is drawn by no view")
    window.isHidden = true
  }

  @Test("a map whose view goes is drawn by no view, so a stack over it keeps to its own space")
  func unshownAsItGoes() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_view"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    let isShown = Held(true)
    let host = UIHostingController(rootView: ShownMap(map: map, isShown: isShown))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { map.shownMap != nil })
    #expect(StackPlacement.shown(map) != nil, "a stack reads the map's own space")

    isShown.value = false
    #expect(await MapWindow.until { map.shownMap == nil }, "its view told it as it went")
    #expect(StackPlacement.shown(map) == nil, "a stack keeps to its own space")
    #expect(StackPlacement.holdsFrame(map), "and holds the frame as the map's read does")

    isShown.value = true
    #expect(await MapWindow.until { map.shownMap != nil }, "drawn again, it tells where it stands")
    window.isHidden = true
  }

  @Test("the map's safe area follows the map as it moves with no layout of its own")
  func safeAreaFollowsAMove() async throws {
    _ = StubTileAPI.installed
    let client = try Mountaya(
      credential: .publishable(key: "pk_test_view"),
      baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
      retry: try RetryPolicy(maxRetries: 0), exchange: Maps.Offline())
    let map = MapEngine(client: client, style: StubTileAPI.styleUrl)
    let offset = Held<CGFloat>(0)
    let host = UIHostingController(rootView: MovedMap(map: map, offset: offset))
    // Laid out as the view alone, the window's safe area aside, as a map drawn full bleed.
    host.safeAreaRegions = []
    let window = MapWindow.showing(host.view)
    let visible = MeasuredMapView.screenRect(window.bounds.inset(by: window.safeAreaInsets))
    func safeArea(at y: CGFloat) -> PixelPadding {
      mapSafeArea(ScreenRect(x: 0, y: Double(y), width: 390, height: 844), visible: visible)
    }
    #expect(await MapWindow.until { map.shownMap?.y == 0 && map.safeArea == safeArea(at: 0) })

    // An offset moves MapLibre's map in its window and lays nothing of it out again.
    offset.value = 200
    #expect(
      await MapWindow.until { map.shownMap?.y == 200 && map.safeArea == safeArea(at: 200) },
      "the safe area read again where the map now stands")
    #expect(map.safeArea != safeArea(at: 0))
    window.isHidden = true
  }
}

/// MovedMap draws `map` over a window's whole size, 390 by 844 points, moved down by `offset`,
/// which moves it in the window with no layout of its own.
private struct MovedMap: View {
  let map: MapEngine
  let offset: Held<CGFloat>

  var body: some View {
    MapView(map)
      .frame(width: 390, height: 844)
      .offset(y: offset.value)
      .frame(width: 390, height: 844, alignment: .topLeading)
  }
}

/// ShownMap draws `map` over a window's whole size while `isShown` holds, and nothing otherwise, as a
/// screen that shows a map and then leaves it.
private struct ShownMap: View {
  let map: MapEngine
  let isShown: Held<Bool>

  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.clear
      if isShown.value {
        MapView(map)
      }
    }
    .frame(width: 390, height: 844)
  }
}
