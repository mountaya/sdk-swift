import Foundation
import MapLibre
import MountayaClient
import RendererSupport
import Testing
import UIKit
import os

@testable import MountayaElements
@testable import MountayaGeo

/// The GeoJSON sources a change to what the map holds may send the renderer again: one, the one
/// it changed, and on a scrub frame the leg it lights, where it lights another. The renderer
/// parses and tiles again every source it is sent, so a change sending every source the map draws
/// pays for all of them on every pointer frame.
private let sourcePushesBudget = 1

/// The drawings of a marker pin a look may cost: one, the first time a marker of that look is
/// shown, which every marker of it shows from then on. Each drawing rasterizes the disc, the ring
/// and the glyph anew.
private let pinImagesBudget = 1

/// MapLibreSuites runs every test of MapLibre's map one at a time: the request hook is the
/// process's, and each test hands it a client of its own.
@Suite(.serialized)
@MainActor
enum MapLibreSuites {}

extension MapLibreSuites {
  @Suite("MapRenderer")
  @MainActor
  struct MapRendererTests {
    private static func engine(
      labelLanguage: RestSchema.Language? = nil, style: URL? = StubTileAPI.styleUrl
    ) throws -> MapEngine {
      _ = StubTileAPI.installed
      let client = try Mountaya(
        credential: .publishable(key: "pk_test_a"), language: "fr",
        baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)))
      return MapEngine(
        client: client, style: style,
        camera: CameraPose(center: [6.86, 45.83], zoom: 10, pitch: 0, bearing: 0),
        labelLanguage: labelLanguage)
    }

    private static let pins = GeoJSONFeatureCollection(features: [
      GeoJSONFeature(
        geometry: .lineString(GeoJSONLineString(coordinates: [[6.86, 45.83], [6.87, 45.84]])),
        properties: ["name": "Sentier"])
    ])

    /// ready draws `map` in a window and returns its renderer once its style is loaded.
    private static func ready(_ map: MapEngine) async throws -> (MapRenderer, UIWindow) {
      let loaded = OSAllocatedUnfairLock(initialState: false)
      let renderer = MapRenderer(engine: map, onReady: { _ in loaded.withLock { $0 = true } })
      let window = MapWindow.showing(renderer.mapView)
      try #require(await MapWindow.until { loaded.withLock { $0 } }, "the style never loaded")
      return (renderer, window)
    }

    /// ownLayers is the map's own layers as MapLibre draws them, bottom to top, where they are the
    /// topmost of the style, above the base map's and MapLibre's own, and nothing where they are
    /// not.
    private static func ownLayers(_ renderer: MapRenderer) -> [String] {
      let all = (renderer.mapView.style?.layers ?? []).map(\.identifier)
      let own = all.filter { !$0.hasPrefix("base-") && !$0.hasPrefix("org.maplibre.") }
      return Array(all.suffix(own.count)) == own ? own : []
    }

    @Test("an engine told its map moved, with no layout of its own, has the map measured again")
    func movedWithNoLayout() async throws {
      let map = try Self.engine()
      let renderer = MapRenderer(engine: map, onReady: nil)
      let holder = UIView()
      renderer.mapView.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
      holder.addSubview(renderer.mapView)
      let window = MapWindow.showing(holder)
      renderer.mapView.layoutIfNeeded()
      let visible = MeasuredMapView.screenRect(window.bounds.inset(by: window.safeAreaInsets))
      func safeArea(at y: Double) -> PixelPadding {
        mapSafeArea(ScreenRect(x: 0, y: y, width: 390, height: 844), visible: visible)
      }
      #expect(await MapWindow.until { map.safeArea == safeArea(at: 0) })

      // The holder carries the map 200 points down, and its chrome tells the engine where it went.
      holder.frame.origin.y = 200
      map.shown(at: ScreenRect(x: 0, y: 200, width: 390, height: 844))
      #expect(
        await MapWindow.until { map.safeArea == safeArea(at: 200) },
        "the safe area read again where the map now stands")
      map.close()
      window.isHidden = true
    }

    @Test("the map draws its state's style, and hands MapLibre's map over once it is loaded")
    func style() async throws {
      let (renderer, window) = try await Self.ready(try Self.engine())
      let style = try #require(renderer.mapView.style)

      #expect(style.layer(withIdentifier: "base-background") != nil)
      #expect(style.layer(withIdentifier: "base-water") is MLNFillStyleLayer)
      #expect(abs(renderer.mapView.zoomLevel - 10) < 0.01)
      #expect(abs(renderer.mapView.centerCoordinate.longitude - 6.86) < 0.001)
      window.isHidden = true
    }

    @Test(
      "layers are drawn above the base map in the registry's order, whatever order they came in")
    func ranks() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(
          id: "cursor", type: .circle, source: "trail", rank: LayerRank.chrome.rank))
      map.addLayer(
        MapLayer(
          id: "route", type: .line, source: "trail",
          rank: LayerRank.itineraryLine.rank,
          paint: ["line-color": "#e64980", "line-width": 4]))
      map.addLayer(
        MapLayer(id: "zone", type: .fill, source: "trail", rank: LayerRank.zone.rank))

      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == ["zone", "route", "cursor"] },
        "\(Self.ownLayers(renderer))")
      let all = (renderer.mapView.style?.layers ?? []).map(\.identifier)
      #expect(
        Array(all.prefix(4)) == ["base-background", "base-elsewhere", "base-water", "base-labels"])

      map.addLayer(
        MapLayer(
          id: "shade", type: .line, source: "trail", rank: LayerRank.hillshade.rank))
      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == ["shade", "zone", "route", "cursor"] },
        "\(Self.ownLayers(renderer))")
      map.removeLayer("route")
      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == ["shade", "zone", "cursor"] },
        "\(Self.ownLayers(renderer))")
      window.isHidden = true
    }

    @Test("a patch the engine merges is the property the map draws, null back to the default")
    func patch() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(
          id: "route", type: .line, source: "trail",
          rank: LayerRank.itineraryLine.rank,
          paint: ["line-color": "#e64980", "line-width": 4, "line-opacity": 0.5],
          layout: ["line-cap": "round"]))
      #expect(
        await MapWindow.until { renderer.mapView.style?.layer(withIdentifier: "route") != nil })
      let drawn = try #require(
        renderer.mapView.style?.layer(withIdentifier: "route") as? MLNLineStyleLayer)
      #expect(Self.number(drawn.lineWidth) == 4)
      #expect(drawn.lineColor.constantValue is UIColor, "\(String(describing: drawn.lineColor))")

      try map.editLayer(
        "route", paint: ["line-width": 8, "line-opacity": nil], layout: ["visibility": "none"])
      #expect(
        await MapWindow.until { Self.number(drawn.lineWidth) == 8 },
        "\(String(describing: drawn.lineWidth))")
      #expect(Self.number(drawn.lineOpacity) == 0.5)
      #expect(!drawn.isVisible)

      try map.editLayer("route", paint: ["line-width": .some(.null)])
      #expect(
        await MapWindow.until { Self.number(drawn.lineWidth) == 1 },
        "\(String(describing: drawn.lineWidth))")
      window.isHidden = true
    }

    @Test("the base map's labels speak the state's language, and change with it")
    func labels() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let labels = try #require(
        renderer.mapView.style?.layer(withIdentifier: "base-labels") as? MLNSymbolStyleLayer)

      #expect(Self.label(labels).contains(#""name:fr""#), "\(Self.label(labels))")
      map.setLabelLanguage(.de)
      #expect(await MapWindow.until { renderer.drawn?.labelLanguage == .de })
      #expect(
        await MapWindow.until { Self.label(labels).contains(#""name:de""#) },
        "\(Self.label(labels))")
      #expect(!Self.label(labels).contains(#""name:fr""#), "\(Self.label(labels))")

      // A layer of the map's own keeps the label it states, whatever the language
      // (`map.style.label-scope`).
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(
          id: "names", type: .symbol, source: "trail", rank: LayerRank.poi.rank,
          layout: ["text-field": ["get", "name"]]))
      #expect(
        await MapWindow.until {
          renderer.mapView.style?.layer(withIdentifier: "names") is MLNSymbolStyleLayer
        })
      map.setLabelLanguage(.it)
      #expect(
        await MapWindow.until { Self.label(labels).contains(#""name:it""#) },
        "\(Self.label(labels))")
      let names = try #require(
        renderer.mapView.style?.layer(withIdentifier: "names") as? MLNSymbolStyleLayer)
      #expect(!Self.label(names).contains("name:"), "\(Self.label(names))")
      window.isHidden = true
    }

    @Test("an edit's magnet measures in the screen's pixels, through MapLibre's projection")
    func magnet() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.jump(to: CameraTarget(center: [6.86, 45.83], zoom: 15, bearing: 0, pitch: 0))
      #expect(await MapWindow.until { abs(renderer.mapView.zoomLevel - 15) < 0.01 })
      let line: [[Double]] = [[6.85, 45.83], [6.87, 45.83]]
      let onLine = renderer.projection.point([6.86, 45.83])
      let near = renderer.projection.position([onLine[0], onLine[1] - 30])
      let far = renderer.projection.position([onLine[0], onLine[1] - 50])

      let snapped = renderer.snapped(near, onto: [line])
      #expect(snapped.isSnapped)
      #expect(abs(snapped.position[1] - 45.83) < 1e-6, "\(snapped.position)")
      #expect(!renderer.snapped(far, onto: [line]).isSnapped)
      window.isHidden = true
    }

    @Test("markers are MapLibre's annotations, each where the state places it, as it changes")
    func markers() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)

      try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83], label: "Refuge"))
      try map.addMarker(MapMarker(id: "summit", position: [6.87, 45.84], color: "#e64980"))
      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).count == 2 })
      let shown = (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
      #expect(Set(shown.map(\.id)) == ["hut", "summit"])
      let hut = try #require(shown.first { $0.id == "hut" })
      #expect(abs(hut.coordinate.longitude - 6.86) < 1e-9)
      #expect(hut.title == "Refuge")

      try map.editMarker("hut", position: [6.9, 45.9])
      map.removeMarker("summit")
      #expect(
        await MapWindow.until {
          let left = (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
          return left.count == 1 && abs((left.first?.coordinate.longitude ?? 0) - 6.9) < 1e-9
        })
      window.isHidden = true
    }

    @Test("a marker kept is moved in place, and only one the state adds or drops is changed")
    func markersInPlace() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)

      try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83], label: "Refuge"))
      try map.addMarker(MapMarker(id: "summit", position: [6.87, 45.84]))
      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).count == 2 })
      let hut = try #require(
        (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
          .first { $0.id == "hut" })

      try map.editMarker("hut", position: [6.9, 45.9], label: "Cabane")
      try map.addMarker(MapMarker(id: "spring", position: [6.88, 45.85]))
      #expect(
        await MapWindow.until {
          (renderer.mapView.annotations ?? []).count == 3
            && abs(hut.coordinate.longitude - 6.9) < 1e-9
        })
      let kept = try #require(
        (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
          .first { $0.id == "hut" })
      #expect(kept === hut, "the marker kept is the annotation shown, moved where it stands")
      #expect(kept.title == "Cabane")
      window.isHidden = true
    }

    @Test("a tap on a marker writes its label to the callout, not MapLibre's, a tap off clears it")
    func markerLabel() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)

      try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83], label: "Refuge"))
      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).count == 1 })
      let hut = try #require(
        (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }.first)
      #expect(!renderer.mapView(renderer.mapView, annotationCanShowCallout: hut))

      let point = renderer.mapView.convert(hut.coordinate, toPointTo: renderer.mapView)
      renderer.tapped(at: point)
      #expect(await MapWindow.until { renderer.callout.markerId == "hut" })
      let moves = renderer.callout.moves
      try map.jump(to: CameraTarget(center: [6.87, 45.84]))
      #expect(await MapWindow.until { renderer.callout.moves > moves })

      renderer.tapped(at: CGPoint(x: 4, y: 4))
      #expect(await MapWindow.until { renderer.callout.markerId == nil })
      window.isHidden = true
    }

    @Test(
      "hot-path budget pin-images: a pin is drawn once a look, however many markers and moves")
    func pinImages() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      for (index, id) in ["a", "b", "c"].enumerated() {
        try map.addMarker(
          MapMarker(id: id, position: [6.86 + Double(index) / 100, 45.83], glyph: "hut"))
      }
      try map.addMarker(MapMarker(id: "red", position: [6.9, 45.9], color: "#e03131"))
      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).count == 4 })
      let shown = (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
      let images = shown.map { renderer.pinImage(of: $0) }

      // The work happened: every marker shows its look's pin, the three huts one image.
      #expect(renderer.pinsDrawn == 2, "two looks, two pins drawn")
      #expect(renderer.pinsDrawn <= pinImagesBudget * 2)
      let huts = shown.indices.filter { shown[$0].glyph == "hut" }.map { images[$0] }
      #expect(huts.count == 3 && huts.allSatisfy { $0 === huts[0] })

      // Thirty moves of a hut, each drawn where it lands: its look draws nothing again.
      for step in 1...30 {
        let longitude = 6.87 + Double(step) / 1_000
        try map.editMarker("b", position: [longitude, 45.83])
        #expect(
          await MapWindow.until {
            (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
              .contains { $0.id == "b" && abs($0.coordinate.longitude - longitude) < 1e-9 }
          }, "move \(step)")
      }
      _ = shown.map { renderer.pinImage(of: $0) }
      #expect(renderer.pinsDrawn <= pinImagesBudget * 2, "\(renderer.pinsDrawn) pins drawn")

      // A look a marker moves to is drawn once, and a new accent draws the looks naming no colour.
      try map.editMarker("a", glyph: "parking")
      #expect(
        await MapWindow.until {
          (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
            .contains { $0.id == "a" && $0.glyph == "parking" }
        })
      _ = shown.map { renderer.pinImage(of: $0) }
      #expect(renderer.pinsDrawn == 3)
      #expect(renderer.pinsDrawn <= pinImagesBudget * 3)
      renderer.accent = HexColor(hex: "#e9501e")
      _ = shown.map { renderer.pinImage(of: $0) }
      #expect(renderer.pinsDrawn == 5, "the hut and the parking again, on the new accent")
      #expect(renderer.pinsDrawn <= pinImagesBudget * 5)
      window.isHidden = true
    }

    /// trail is a source's features: one line north of the map's centre, `offset` hundredths east.
    private static func trail(_ offset: Int) -> GeoJSONFeatureCollection {
      let east = 6.85 + Double(offset) / 100
      return GeoJSONFeatureCollection(features: [
        GeoJSONFeature(
          geometry: .lineString(GeoJSONLineString(coordinates: [[east, 45.83], [east, 45.85]])),
          properties: [:])
      ])
    }

    @Test(
      "hot-path budget source-pushes: a change sends its source alone, a scrub frame its leg alone")
    func sourcePushes() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let probe = RenderProbe()
      renderer.probe = probe
      // Five sources of GeoJSON the map draws, each a line of its own.
      let ids = ["a", "b", "c", "d", "e"]
      for (index, id) in ids.enumerated() {
        map.addSource(MapSource(id: id, kind: .geoJson(Self.trail(index))))
        map.addLayer(
          MapLayer(id: id, type: .line, source: id, rank: LayerRank.itineraryLine.rank))
      }
      #expect(
        await MapWindow.until { ids.allSatisfy { probe["source " + $0] == 1 } }, "\(probe.counts)")
      /// sentSince is every source sent since the probe counted `counts`, by its name, and how
      /// often.
      func sentSince(_ counts: [String: Int]) -> [String: Int] {
        var sent: [String: Int] = [:]
        for (part, count) in probe.counts where count > counts[part, default: 0] {
          sent[part] = count - counts[part, default: 0]
        }
        return sent
      }

      // A change to one source sends that source alone.
      var counts = probe.counts
      map.addSource(MapSource(id: "c", kind: .geoJson(Self.trail(9))))
      #expect(await MapWindow.until { renderer.drawn == map.state })
      let changed = sentSince(counts)
      #expect(changed == ["source c": 1], "\(changed)")
      #expect(changed.values.reduce(0, +) <= sourcePushesBudget)

      // Sixty frames of a profile's cursor along an itinerary: its marker moved on each, and the
      // leg it points at lit as it moves from one to the other.
      counts = probe.counts
      let drawing = ItineraryDrawing(resolved: Itineraries.resolved, legs: nil)
      var link = MapLink<Int>(markerId: profileCursorMarkerId)
      let samples = [0, 1, 2, 4, 5, 4, 2, 1]
      var lit: [GeoJSONGeometry?] = [nil]
      for frame in 0..<60 {
        let index = samples[frame % samples.count]
        let target = drawing.cursorTarget(at: index)
        link.point(
          at: index, value: index, target: target, isEnabled: true, onHover: nil, map: map,
          markerColor: nil, emphasisColor: nil)
        #expect(await MapWindow.until { renderer.drawn == map.state }, "frame \(frame)")
        lit.append(target.stretch)
      }
      let litAnew = zip(lit, lit.dropFirst()).filter { $0 != $1 }.count
      let scrubbed = sentSince(counts)

      // The work happened: the marker stands on the last sample, and the leg was lit anew.
      let last = drawing.series.points[samples[59 % samples.count]].lngLat
      #expect(map.state.markers.first { $0.id == profileCursorMarkerId }?.position == last)
      #expect(litAnew > 1)
      // Each frame sent the emphasis slot's source at most, and only where it lit another leg.
      let emphasis = "source " + GeometrySlot.emphasis.sourceId
      #expect(Set(scrubbed.keys) == [emphasis], "\(scrubbed)")
      #expect(
        scrubbed.values.reduce(0, +) <= sourcePushesBudget * litAnew,
        "\(scrubbed) over 60 frames, a leg lit anew \(litAnew) times")
      window.isHidden = true
    }

    @Test("a tap tells onTap where it fell and on which marker; one placing a waypoint places it")
    func taps() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.jump(to: CameraTarget(center: [6.86, 45.83], zoom: 15, bearing: 0, pitch: 0))
      #expect(await MapWindow.until { abs(renderer.mapView.zoomLevel - 15) < 0.01 })
      var taps: [MapTap] = []
      renderer.onTap = { taps.append($0) }
      try map.addMarker(MapMarker(id: "hut", position: [6.86, 45.83]))
      let onHut = renderer.projection.point([6.86, 45.83])

      renderer.tapped(at: CGPoint(x: onHut[0] + 10, y: onHut[1]))
      renderer.tapped(at: CGPoint(x: onHut[0], y: onHut[1] + 100))
      #expect(await MapWindow.until { taps.count == 2 })
      #expect(taps.map(\.marker) == ["hut", nil])
      let away = renderer.projection.position([onHut[0], onHut[1] + 100])
      #expect(abs((taps.last?.position[1] ?? 0) - away[1]) < 1e-9)
      #expect(taps.last?.point == [onHut[0], onHut[1] + 100])

      map.setActiveSegments([[[6.85, 45.83], [6.87, 45.83]]])
      try map.beginWaypointEdit("w1")
      renderer.tapped(at: CGPoint(x: onHut[0] + 50, y: onHut[1] - 30))
      let placed = try #require(map.state.waypointEdit)
      #expect(placed.isSnapped)
      #expect(abs((placed.position?[1] ?? 0) - 45.83) < 1e-6, "\(placed)")
      #expect(
        await MapWindow.until {
          (renderer.mapView.annotations ?? []).contains { $0 is DraftAnnotation }
        })
      #expect(taps.count == 2, "a tap the edit takes is told to no handler")
      map.endWaypointEdit()
      #expect(
        await MapWindow.until {
          !(renderer.mapView.annotations ?? []).contains { $0 is DraftAnnotation }
        })
      window.isHidden = true
    }

    @Test(
      "the zoom range and the pan lock are MapLibre's camera limits, what the view shows held within the lock"
    )
    func limits() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let unlocked = renderer.mapView.maximumScreenBounds
      let lock: [Double] = [6.7, 45.7, 7.0, 46.0]

      try map.setZoomBounds(min: 5, max: 12)
      #expect(await MapWindow.until { renderer.mapView.maximumZoomLevel == 12 })
      #expect(renderer.mapView.minimumZoomLevel == 5)
      try map.setZoomBounds(min: 14, max: 16)
      #expect(await MapWindow.until { renderer.mapView.minimumZoomLevel == 14 })
      #expect(renderer.mapView.maximumZoomLevel == 16)
      #expect(abs(renderer.mapView.zoomLevel - 14) < 0.01, "the engine held the camera at 14")
      try map.setZoomBounds(min: .released, max: .released)
      #expect(await MapWindow.until { renderer.mapView.maximumZoomLevel == 25.5 })
      // The floor handed over is 0, under which MapLibre Native draws nothing; it reads back the
      // zoom at which the world fills the view, its own floor above that.
      #expect(
        renderer.mapView.minimumZoomLevel < 1,
        "MapLibre's floor once released: \(renderer.mapView.minimumZoomLevel)")

      try map.jump(to: CameraTarget(center: [6.85, 45.85], zoom: 12, bearing: 0, pitch: 0))
      try map.setMaxBounds(lock)
      #expect(await MapWindow.until { renderer.drawn?.maxBounds == lock })
      #expect(abs(renderer.mapView.maximumScreenBounds.ne.longitude - 7.0) < 1e-9)
      #expect(abs(renderer.mapView.maximumScreenBounds.sw.latitude - 45.7) < 1e-9)
      #expect(Self.showsWithin(lock, in: renderer), "\(Self.shown(renderer))")
      try map.jump(to: CameraTarget(center: [8.0, 47.0], zoom: 12, bearing: 0, pitch: 0))
      #expect(await MapWindow.until { renderer.drawn?.camera.center == [8.0, 47.0] })
      #expect(
        Self.showsWithin(lock, in: renderer),
        "a camera set outside the lock is held within it: \(Self.shown(renderer))")
      // The view zooms out no farther than the zoom at which it fits within the lock, about 10.4
      // for a lock of 0.3 degrees in a view 390 points by 844, as the web's `maxBounds` holds it.
      try map.jump(to: CameraTarget(center: [6.85, 45.85], zoom: 3, bearing: 0, pitch: 0))
      #expect(await MapWindow.until { renderer.drawn?.camera.zoom == 3 })
      #expect(
        renderer.mapView.zoomLevel > 10,
        "zoomed out no farther than the lock fills the view: \(renderer.mapView.zoomLevel)")
      #expect(Self.showsWithin(lock, in: renderer), "\(Self.shown(renderer))")
      // MapLibre's own camera is held alike, whoever moves it.
      renderer.mapView.setZoomLevel(2, animated: false)
      #expect(renderer.mapView.zoomLevel > 10, "\(renderer.mapView.zoomLevel)")
      #expect(Self.showsWithin(lock, in: renderer), "\(Self.shown(renderer))")

      try map.setMaxBounds(nil)
      #expect(
        await MapWindow.until {
          renderer.mapView.maximumScreenBounds.ne.longitude == unlocked.ne.longitude
        })
      try map.jump(to: CameraTarget(center: [8.0, 47.0], zoom: 3, bearing: 0, pitch: 0))
      #expect(
        await MapWindow.until { abs(renderer.mapView.zoomLevel - 3) < 0.01 },
        "a lift lets the camera out: \(renderer.mapView.zoomLevel)")
      #expect(abs(renderer.mapView.centerCoordinate.longitude - 8.0) < 1e-6)
      window.isHidden = true
    }

    @Test("a camera a lock moves is reported to the engine, so the state is the map as shown")
    func heldCamera() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let lock: [Double] = [6.7, 45.7, 7.0, 46.0]
      try map.jump(to: CameraTarget(center: [8.0, 47.0], zoom: 12, bearing: 0, pitch: 0))
      #expect(
        await MapWindow.until { abs(renderer.mapView.centerCoordinate.longitude - 8.0) < 1e-6 })

      try map.setMaxBounds(lock)
      #expect(await MapWindow.until { map.state.camera.center[0] < 7.0 }, "\(map.state.camera)")
      let center = map.state.camera.center
      #expect(
        (lock[0]...lock[2]).contains(center[0]) && (lock[1]...lock[3]).contains(center[1]),
        "\(center)")
      #expect(abs(center[0] - renderer.mapView.centerCoordinate.longitude) < 1e-7)
      #expect(abs(center[1] - renderer.mapView.centerCoordinate.latitude) < 1e-7)
      #expect(Self.showsWithin(lock, in: renderer), "\(Self.shown(renderer))")
      window.isHidden = true
    }

    @Test("a camera the app sets as the limits change is the one shown, never the one they held")
    func cameraAfterLimits() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.setMaxBounds([6.7, 45.7, 7.0, 46.0])
      try map.jump(to: CameraTarget(center: [8.0, 47.0], zoom: 12, bearing: 0, pitch: 0))
      #expect(await MapWindow.until { renderer.drawn?.camera.center == [8.0, 47.0] })

      // The lock lifted and a camera set in one turn: the renderer draws the lift first, while the
      // engine already holds the camera, and MapLibre's camera held under the lock is no news.
      try map.setMaxBounds(nil)
      let wanted = CameraPose(center: [7.5, 46.5], zoom: 3, pitch: 0, bearing: 0)
      try map.jump(to: CameraTarget(center: wanted.center, zoom: 3, bearing: 0, pitch: 0))
      #expect(
        await MapWindow.until { renderer.drawn == map.state && renderer.drawn?.maxBounds == nil })
      #expect(map.state.camera == wanted, "\(map.state.camera)")
      #expect(
        await MapWindow.until { abs(renderer.mapView.zoomLevel - 3) < 0.01 },
        "\(renderer.mapView.zoomLevel)")
      #expect(abs(renderer.mapView.centerCoordinate.longitude - 7.5) < 1e-6)
      window.isHidden = true
    }

    @Test("the camera at rest is told to onCameraChange, whoever moved it")
    func cameraChange() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      var rested: [CameraPose] = []
      renderer.onCameraChange = { rested.append($0) }

      try map.jump(to: CameraTarget(center: [7.5, 46.0], zoom: 13, bearing: 0, pitch: 0))
      #expect(await MapWindow.until { rested.contains { abs($0.zoom - 13) < 0.01 } })
      renderer.mapView(renderer.mapView, regionDidChangeWith: .gesturePan, animated: false)
      #expect(rested.count >= 2)
      #expect(map.state.camera == rested.last, "a reader's move is the state's camera too")
      window.isHidden = true
    }

    @Test("a move the reader begins closes the readout as it begins, and the app's as it is asked")
    func readoutClosedAsMovesBegin() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      map.longTapped(at: [100, 100], position: [6.86, 45.83])
      #expect(map.readout != nil)
      renderer.mapView(renderer.mapView, regionWillChangeWith: .programmatic, animated: true)
      #expect(map.readout != nil, "a move the app asked for closed it as it was asked")
      renderer.mapView(renderer.mapView, regionWillChangeWith: .gesturePan, animated: false)
      #expect(map.readout == nil, "closed as the reader's pan begins, not as it comes to rest")

      map.longTapped(at: [100, 100], position: [6.86, 45.83])
      try map.jump(to: CameraTarget(center: [7.5, 46.0], zoom: 11, bearing: 0, pitch: 0))
      #expect(map.readout == nil, "closed as the app's move is asked")
      window.isHidden = true
    }

    @Test("a camera the app sets moves MapLibre's")
    func camera() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.jump(to: CameraTarget(center: [7.5, 46.0], zoom: 13, bearing: 45, pitch: 30))
      #expect(await MapWindow.until { renderer.drawn?.camera.zoom == 13 }, "never drawn")

      #expect(await MapWindow.until { abs(renderer.mapView.zoomLevel - 13) < 0.01 })
      #expect(abs(renderer.mapView.centerCoordinate.latitude - 46.0) < 0.001)
      #expect(abs(renderer.mapView.direction - 45) < 0.01)
      #expect(abs(Double(renderer.mapView.camera.pitch) - 30) < 0.01)
      window.isHidden = true
    }

    @Test("an image the style names and the map does not hold is answered with its marker sprite")
    func missingImages() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)

      let hut = try #require(renderer.missingImage("section-icon-hut-1C7ED6"))
      #expect(hut.size == CGSize(width: 48, height: 48))
      #expect(hut.renderingMode == .alwaysOriginal)
      #expect(
        Pixels.pixel(hut, at: CGPoint(x: 24, y: 8))?.isNear(
          Pixels.Pixel(red: 0x1c, green: 0x7e, blue: 0xd6, alpha: 255)) == true)
      #expect(renderer.missingImage("poi-icon-campground-0b7285") != nil)
      #expect(renderer.missingImage("section-icon-road-access-permit-9c36b5") != nil)
      // Any other id is left missing: one under no prefix, one whose tail is no glyph and colour,
      // and one naming a glyph the set cannot draw.
      #expect(renderer.missingImage("some-basemap-sprite") == nil)
      #expect(renderer.missingImage("section-icon-hut-fff") == nil)
      #expect(renderer.missingImage("section-icon-activity-hiking-1c7ed6") == nil)
      // MapLibre asks for each image a symbol layer names as it lays a symbol out, and adds the
      // sprite it is answered with to the style under the id.
      map.addSource(
        MapSource(
          id: "pins",
          kind: .geoJson(
            GeoJSONFeatureCollection(features: [
              GeoJSONFeature(
                geometry: .point(GeoJSONPoint(coordinates: [6.86, 45.83])), properties: [:])
            ]))))
      map.addLayer(
        MapLayer(
          id: "waypoints", type: .symbol, source: "pins",
          rank: LayerRank.itineraryPoint.rank,
          layout: ["icon-image": "section-icon-flag-start-e03131", "icon-allow-overlap": true]))
      map.addLayer(
        MapLayer(
          id: "basemap-icons", type: .symbol, source: "pins",
          rank: LayerRank.itineraryPoint.rank,
          layout: ["icon-image": "some-basemap-sprite", "icon-allow-overlap": true]))
      #expect(
        await MapWindow.until {
          renderer.mapView.style?.image(forName: "section-icon-flag-start-e03131") != nil
        }, "MapLibre never drew the sprite its style names")
      #expect(renderer.mapView.style?.image(forName: "some-basemap-sprite") == nil)
      window.isHidden = true
    }

    @Test("a map's sprites are drawn from the glyph set its engine is given")
    func handedGlyphs() async throws {
      _ = StubTileAPI.installed
      let licensed = try #require(
        GlyphSet(
          name: "licensed", paint: .fill, markup: ["refuge": #"<rect width="24" height="24"/>"#]))
      let map = MapEngine(
        client: try Mountaya(
          credential: .publishable(key: "pk_test_a"),
          baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles))),
        style: StubTileAPI.styleUrl, glyphs: licensed)
      let (renderer, window) = try await Self.ready(map)

      let refuge = try #require(renderer.missingImage("section-icon-refuge-000000"))
      // The glyph, a square filling its box, is the white square at the sprite's centre.
      #expect(
        Pixels.pixel(refuge, at: CGPoint(x: 24, y: 24))?.isNear(
          Pixels.Pixel(red: 255, green: 255, blue: 255, alpha: 255)) == true)
      #expect(renderer.missingImage("section-icon-hut-000000") == nil)
      // A marker's pin carries a glyph of that set too.
      try map.addMarker(MapMarker(id: "refuge", position: [6.86, 45.83], glyph: "refuge"))
      #expect(await MapWindow.until { !(renderer.mapView.annotations ?? []).isEmpty })
      let pinned = try #require(
        (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }.first)
      let pin = try #require(
        renderer.mapView(renderer.mapView, viewFor: pinned) as? MarkerPinView)
      // Inside the glyph's square and outside where a dot would be: the square is drawn.
      #expect(
        Pixels.pixel(pin.image, at: CGPoint(x: 7, y: 7))?.isNear(
          Pixels.Pixel(red: 255, green: 255, blue: 255, alpha: 255)) == true)
      window.isHidden = true
    }

    private static let white = Pixels.Pixel(red: 255, green: 255, blue: 255, alpha: 255)
    private static let accent = Pixels.Pixel(red: 0x1c, green: 0x7e, blue: 0xd6, alpha: 255)

    @Test("a marker is shown as its pin: the accent and a dot where it names neither, else its own")
    func pins() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let red = Pixels.Pixel(red: 0xe0, green: 0x31, blue: 0x31, alpha: 255)

      try map.addMarker(MapMarker(id: "plain", position: [6.86, 45.83]))
      try map.addMarker(
        MapMarker(id: "hut", position: [6.87, 45.84, 1834], color: "#e03131", glyph: "hut"))
      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).count == 2 })
      let shown = (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
      let plain = try #require(shown.first { $0.id == "plain" })
      let hut = try #require(shown.first { $0.id == "hut" })
      #expect(abs(hut.coordinate.latitude - 45.84) < 1e-9, "an altitude is accepted and left out")

      let plainPin = try #require(
        renderer.mapView(renderer.mapView, viewFor: plain) as? MarkerPinView)
      #expect(plainPin.frame.size == CGSize(width: 28, height: 28))
      #expect(Pixels.pixel(plainPin.image, at: CGPoint(x: 14, y: 6))?.isNear(Self.accent) == true)
      #expect(Pixels.pixel(plainPin.image, at: CGPoint(x: 14, y: 14))?.isNear(Self.white) == true)
      #expect(Pixels.pixel(plainPin.image, at: CGPoint(x: 14, y: 1.5))?.isNear(Self.white) == true)
      let hutPin = try #require(renderer.mapView(renderer.mapView, viewFor: hut) as? MarkerPinView)
      let described = markerPinImage(
        describeMarkerPin(color: "#e03131", glyph: "hut", in: map.glyphs),
        accent: HexColor(hex: "#1c7ed6"),
        in: map.glyphs)
      #expect(hutPin.image.pngData() == described.pngData(), "the pin the rule describes")
      #expect(Pixels.pixel(hutPin.image, at: CGPoint(x: 14, y: 4.5))?.isNear(red) == true)
      #expect(
        await MapWindow.until { renderer.mapView.view(for: plain) is MarkerPinView },
        "MapLibre shows the marker through its pin")

      // An edit draws the pin again, with what the edit changed.
      try map.editMarker("plain", glyph: "hut")
      #expect(
        await MapWindow.until {
          (renderer.mapView.annotations ?? []).compactMap { $0 as? MarkerAnnotation }
            .contains { $0.id == "plain" && $0.glyph == "hut" }
        })
      window.isHidden = true
    }

    @Test(
      "a marker naming no colour is drawn in the host's accent, and a new accent draws it again")
    func pinsTakeTokens() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let orange = Pixels.Pixel(red: 0xe9, green: 0x50, blue: 0x1e, alpha: 255)
      try map.addMarker(MapMarker(id: "plain", position: [6.86, 45.83]))
      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).count == 1 })
      let before = try #require(renderer.mapView.annotations?.first as? MarkerAnnotation)
      #expect(
        renderer.accent == HexColor(hex: "#1c7ed6"), "the standard accent, under the light scheme")

      renderer.accent = HexColor(hex: "#e9501e")

      let after = try #require(renderer.mapView.annotations?.first as? MarkerAnnotation)
      #expect(after === before, "the marker is kept, and its look drawn again in the new accent")
      let pin = try #require(renderer.mapView(renderer.mapView, viewFor: after) as? MarkerPinView)
      #expect(Pixels.pixel(pin.image, at: CGPoint(x: 14, y: 6))?.isNear(orange) == true)
      #expect(Pixels.pixel(pin.image, at: CGPoint(x: 14, y: 14))?.isNear(Self.white) == true)
      let red = try #require(
        renderer.mapView(
          renderer.mapView,
          viewFor: MarkerAnnotation(
            MapMarker(id: "red", position: [6.86, 45.83], color: "#e03131"))) as? MarkerPinView)
      #expect(
        Pixels.pixel(red.image, at: CGPoint(x: 14, y: 6))?.isNear(
          Pixels.Pixel(red: 0xe0, green: 0x31, blue: 0x31, alpha: 255)) == true,
        "a marker naming its colour keeps it")
      window.isHidden = true
    }

    @Test(
      "a data element's cursor marker is the pin's dot, and the leg it points at the emphasis line")
    func profileLinks() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let leg = GeoJSONGeometry.lineString(
        GeoJSONLineString(coordinates: [[6.85, 45.83], [6.87, 45.84]]))
      var link = MapLink<Int>(markerId: profileCursorMarkerId)
      link.write(
        MapTarget(lngLat: [6.86, 45.835], stretch: leg), on: map, markerColor: nil,
        emphasisColor: nil)

      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).count == 1 })
      let cursor = try #require(renderer.mapView.annotations?.first as? MarkerAnnotation)
      #expect(cursor.id == profileCursorMarkerId && cursor.glyph == cursorMarkerGlyph)
      let pin = try #require(renderer.mapView(renderer.mapView, viewFor: cursor) as? MarkerPinView)
      let dot = markerPinImage(
        describeMarkerPin(color: nil, glyph: nil, in: map.glyphs),
        accent: HexColor(hex: "#1c7ed6"), in: map.glyphs)
      #expect(
        pin.image.pngData() == dot.pngData(),
        "the marker set draws no filled pin, so the marker is the pin's dot")
      #expect(Pixels.pixel(pin.image, at: CGPoint(x: 14, y: 14))?.isNear(Self.white) == true)
      let line = GeometrySlot.emphasis.sourceId + "-line"
      #expect(await MapWindow.until { renderer.mapView.style?.layer(withIdentifier: line) != nil })

      link.write(MapTarget(), on: map, markerColor: nil, emphasisColor: nil)
      #expect(await MapWindow.until { (renderer.mapView.annotations ?? []).isEmpty })
      #expect(map.geometry(in: .emphasis).geometry == nil)
      window.isHidden = true
    }

    @Test("a restricted stretch is striped in its kind's pattern, which MapLibre asks for and adds")
    func stripes() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      // The permit kind's colour, `roadAccessColor(.permit)`.
      let purple = Pixels.Pixel(red: 0x9c, green: 0x36, blue: 0xb5, alpha: 255)

      let permit = try #require(renderer.missingImage("road-access-stripe-permit"))
      #expect(permit.size == CGSize(width: 16, height: 16))
      #expect(permit.renderingMode == .alwaysOriginal)
      #expect(
        Pixels.pixel(permit, at: CGPoint(x: 8, y: 8))?.isNear(purple) == true,
        "on the stripe through the tile")
      #expect(
        Pixels.pixel(permit, at: CGPoint(x: 4, y: 4))?.isNear(Self.white) == true,
        "the white ground between two stripes")
      #expect(renderer.missingImage("road-access-stripe-local-access") != nil)
      #expect(renderer.missingImage("road-access-stripe-toll") == nil, "a tail that is no kind")

      map.addSource(
        MapSource(
          id: "stretches",
          kind: .geoJson(
            GeoJSONFeatureCollection(features: [
              GeoJSONFeature(
                geometry: .lineString(
                  GeoJSONLineString(coordinates: [[6.85, 45.83], [6.87, 45.83]])),
                properties: ["kind": "permit"])
            ]))))
      map.addLayer(
        MapLayer(
          id: "stretch-stripes", type: .line, source: "stretches",
          rank: LayerRank.itineraryRestriction.rank,
          paint: [
            "line-width": 8,
            "line-pattern": [
              "match", ["get", "kind"], "permit", "road-access-stripe-permit",
              "road-access-stripe-restricted",
            ],
          ]))
      #expect(
        await MapWindow.until {
          renderer.mapView.style?.image(forName: "road-access-stripe-permit") != nil
        }, "MapLibre never drew the stripes its style names")
      window.isHidden = true
    }

    /// trip is a specification of an itinerary on the stub Tile API: its line under its casing, and
    /// its waypoints.
    private static let trip = TileSchema.TileSpecification(sources: [
      TileSchema.TileSource(
        id: "trip",
        layers: [
          TileSchema.TileLayer(
            id: "trip-lines-casing", key: "lines", layout: nil, paint: ["line-width": 7],
            source_layer: "itinerary_lines", type: .line, zoom_max: 22, zoom_min: 0),
          TileSchema.TileLayer(
            id: "trip-lines", key: "lines", layout: nil, paint: ["line-width": 4],
            source_layer: "itinerary_lines", type: .line, zoom_max: 22, zoom_min: 0),
          TileSchema.TileLayer(
            id: "trip-points", key: "points", layout: nil, paint: nil,
            source_layer: "itinerary_points", type: .symbol, zoom_max: 22,
            zoom_min: 0),
        ], tiles: ["https://tiles.example.test/v1/itineraries/trip/{z}/{x}/{y}"],
        type: .vector, zoom_max: 14, zoom_min: 0)
    ])

    @Test(
      "a specification draws its restricted stretches beside its line, and its content survives a switch"
    )
    func restrictedStretches() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.setSpecification(Self.trip, named: "trip")
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(
          id: "route", type: .line, source: "trail",
          rank: LayerRank.itineraryLine.rank))
      let drawn = map.state.layers.map(\.id)
      #expect(drawn.contains("trip-lines__road-access-stripe"))
      #expect(drawn.contains("trip-lines__road-access-icon"))
      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == drawn }, "\(Self.ownLayers(renderer))")

      let stripes = try #require(
        renderer.mapView.style?.layer(withIdentifier: "trip-lines__road-access-stripe")
          as? MLNLineStyleLayer)
      let icons = try #require(
        renderer.mapView.style?.layer(withIdentifier: "trip-lines__road-access-icon")
          as? MLNSymbolStyleLayer)
      #expect(stripes.sourceLayerIdentifier == "itinerary_restrictions")
      #expect(stripes.sourceIdentifier == "trip")
      #expect(icons.sourceLayerIdentifier == "itinerary_restrictions")
      #expect(stripes.isVisible && icons.isVisible, "shown by default")
      map.setAccessRestrictionsVisibility(false)
      #expect(await MapWindow.until { !stripes.isVisible && !icons.isVisible })
      #expect(
        renderer.mapView.style?.layer(withIdentifier: "trip-lines")?.isVisible == true,
        "the itinerary's own line stays shown")

      // A base map switched to draws the map's content again on it, the layer the app added by hand
      // and the stretches' hidden word included.
      let dark = try #require(
        URL(string: "https://tiles.example.test/v1/terrains/outdoor/dark/style"))
      map.setStyle(dark)
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == dark && Self.ownLayers(renderer) == drawn
        }, "\(Self.ownLayers(renderer))")
      #expect(
        renderer.mapView.style?.layer(withIdentifier: "trip-lines__road-access-stripe")?.isVisible
          == false)

      // A base map that does not arrive gives the map back the one shown, its content drawn on it.
      let missing = try #require(
        URL(string: "https://tiles.example.test/v1/terrains/missing/light/style"))
      map.setStyle(missing)
      #expect(
        await MapWindow.until { map.state.style == dark }, "the engine went back to the shown style"
      )
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == dark && Self.ownLayers(renderer) == drawn
        }, "\(Self.ownLayers(renderer))")
      window.isHidden = true
    }

    @Test("a picked result is drawn above the content, its pin answered, and kept across a switch")
    func searchHighlight() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(
          id: "route", type: .line, source: "trail",
          rank: LayerRank.itineraryLine.rank))

      map.setSearchHighlight(
        .poi(point: [6.86, 45.83], category: .peak), accent: HexColor(hex: "#1c7ed6"))
      let drawn = ["route", "mountaya-search-highlight-poi"]
      #expect(map.state.layers.map(\.id) == drawn)
      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == drawn }, "\(Self.ownLayers(renderer))")
      let pin = try #require(
        renderer.mapView.style?.layer(withIdentifier: "mountaya-search-highlight-poi")
          as? MLNSymbolStyleLayer)
      #expect(pin.sourceIdentifier == "mountaya-search-highlight")
      #expect(renderer.missingImage("poi-icon-mountain-5d4037") != nil, "the pin's sprite")

      // A base map switched to draws the highlight again on it, above the content.
      let dark = try #require(
        URL(string: "https://tiles.example.test/v1/terrains/outdoor/dark/style"))
      map.setStyle(dark)
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == dark && Self.ownLayers(renderer) == drawn
        }, "\(Self.ownLayers(renderer))")

      // The latest call wins, and a way's ends read the points alone.
      map.setSearchHighlight(
        .way(anchor: [6.865, 45.835], bounds: nil, coordinates: [[6.86, 45.83], [6.87, 45.84]]))
      let way = [
        "route", "mountaya-search-highlight-halo", "mountaya-search-highlight-casing",
        "mountaya-search-highlight-line", "mountaya-search-highlight-endpoints",
      ]
      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == way }, "\(Self.ownLayers(renderer))")
      let ends = try #require(
        renderer.mapView.style?.layer(withIdentifier: "mountaya-search-highlight-endpoints")
          as? MLNCircleStyleLayer)
      #expect(ends.predicate != nil, "a circle filtered to the points")

      // A clear takes it down at once, its source with it.
      map.setSearchHighlight(nil)
      #expect(
        await MapWindow.until {
          Self.ownLayers(renderer) == ["route"]
            && renderer.mapView.style?.source(withIdentifier: "mountaya-search-highlight") == nil
        })
      window.isHidden = true
    }

    @Test("the geometry slots and a Data API result are drawn at their bands, and taken off")
    func slots() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      Self.drawTrail(on: map)
      map.setGeometry(
        .lineString(GeoJSONLineString(coordinates: [[6.85, 45.83], [6.87, 45.84]])), in: .preview)
      map.setGeometry(.point(GeoJSONPoint(coordinates: [6.86, 45.83])), in: .highlight)
      let band = try JSONDecoder().decode(
        DataSchema.Isochrone.self,
        from: Data(
          #"{"value": 600, "geometry": {"type": "Polygon", "coordinates": [[[6.85, 45.82], [6.87, 45.82], [6.87, 45.84], [6.85, 45.82]]]}}"#
            .utf8))
      let reach = try await map.addIsochrones(
        DataSchema.IsochronesResult { $0.isochrones = [band] })
      let drawn = map.state.layers.map(\.id)
      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == drawn }, "\(Self.ownLayers(renderer))")

      let reached = drawn.indices.filter { map.state.layers[$0].source == "mountaya-\(reach.id)" }
      let route = try #require(drawn.firstIndex(of: "route"))
      let preview = try #require(drawn.firstIndex(of: "mountaya-preview-line"))
      let huts = try #require(drawn.firstIndex(of: "huts"))
      let highlight = try #require(drawn.firstIndex(of: "mountaya-highlight-point"))
      #expect(!reached.isEmpty && reached.allSatisfy { $0 < route }, "the result under the route")
      #expect(route < preview && preview < huts, "the preview just above the route")
      #expect(highlight == drawn.count - 1, "the highlight above everything")

      map.clearGeometry(in: .preview)
      map.removeAnalysis(reach.id)
      let left = map.state.layers.map(\.id)
      #expect(!left.contains("mountaya-preview-line"))
      #expect(
        await MapWindow.until { Self.ownLayers(renderer) == left }, "\(Self.ownLayers(renderer))")
      #expect(renderer.mapView.style?.source(withIdentifier: "mountaya-\(reach.id)") == nil)
      window.isHidden = true
    }

    /// StyleAsks watches MapLibre's map being asked for one style, through its own setter: while it
    /// watches, the setter's implementation is exchanged for `recordedStyleUrl(_:)`, which signs a
    /// request to that style through the request hook as it is asked, keeps the key the hook gave
    /// it, then sets the style as MapLibre does.
    @MainActor
    enum StyleAsks {
      /// watched is the style watched, nil while nothing is.
      static var watched: URL?
      /// signed is the key a request to the style watched carried, each time it was asked.
      static var signed: [String?] = []

      /// watch watches `style`, or stops watching where it is nil.
      static func watch(_ style: URL?) {
        if (watched == nil) != (style == nil) {
          let setter = class_getInstanceMethod(
            MLNMapView.self, #selector(setter: MLNMapView.styleURL))
          let recorded = class_getInstanceMethod(
            MLNMapView.self, #selector(MLNMapView.recordedStyleUrl(_:)))
          if let setter, let recorded {
            method_exchangeImplementations(setter, recorded)
          }
        }
        if style != nil {
          signed = []
        }
        watched = style
      }
    }

    /// Told is every event an engine tells, gathered on the main actor as they arrive, until the
    /// engine ends its stream.
    @MainActor
    final class Told {
      private(set) var events: [MapEvent] = []

      init(_ map: MapEngine) {
        let stream = map.events()
        Task { [weak self] in
          for await event in stream {
            self?.events.append(event)
          }
        }
      }
    }

    /// trail draws a line along 45.83 from 6.85 to 6.87, an itinerary's leg, and a waypoint at its
    /// middle, each at its band.
    private static func drawTrail(on map: MapEngine) {
      map.addSource(
        MapSource(
          id: "trail",
          kind: .geoJson(
            GeoJSONFeatureCollection(features: [
              GeoJSONFeature(
                geometry: .lineString(
                  GeoJSONLineString(coordinates: [[6.85, 45.83], [6.87, 45.83]])),
                properties: ["segment_id": "climb"]),
              GeoJSONFeature(
                geometry: .point(GeoJSONPoint(coordinates: [6.86, 45.83])),
                properties: ["waypoint_id": "hut", "kinds": ["refuge", "water"], "beds": 24]),
            ]))))
      map.addLayer(
        MapLayer(
          id: "route", type: .line, source: "trail",
          rank: LayerRank.itineraryLine.rank,
          paint: ["line-width": 12], filter: ["==", ["geometry-type"], "LineString"]))
      map.addLayer(
        MapLayer(
          id: "huts", type: .circle, source: "trail",
          rank: LayerRank.itineraryPoint.rank, paint: ["circle-radius": 10],
          filter: ["==", ["geometry-type"], "Point"]))
    }

    @Test(
      "a move the engine hands MapLibre lands where the engine holds it, jump, ease and fly alike")
    func cameraLanding() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)

      try map.ease(to: CameraTarget(center: [7.0, 46.0], zoom: 12))
      #expect(map.state.camera.zoom == 12)
      #expect(
        await MapWindow.until {
          abs(renderer.mapView.zoomLevel - 12) < 0.01
            && abs(renderer.mapView.centerCoordinate.longitude - 7.0) < 1e-6
        }, "\(Self.shown(renderer))")
      try map.fly(to: CameraTarget(center: [6.9, 45.9], zoom: 13, bearing: 30))
      #expect(
        await MapWindow.until {
          abs(renderer.mapView.zoomLevel - 13) < 0.01 && abs(renderer.mapView.direction - 30) < 0.01
            && abs(renderer.mapView.centerCoordinate.latitude - 45.9) < 1e-6
        }, "\(Self.shown(renderer))")
      try map.jump(to: CameraTarget(pitch: 40))
      #expect(abs(Double(renderer.mapView.camera.pitch) - 40) < 0.01)
      #expect(abs(renderer.mapView.zoomLevel - 13) < 0.01, "a move keeps what it leaves out")
      #expect(abs(renderer.mapView.direction - 30) < 0.01)

      map.zoomIn()
      #expect(map.state.camera.zoom == 14)
      #expect(await MapWindow.until { abs(renderer.mapView.zoomLevel - 14) < 0.01 })
      map.resetNorth()
      #expect(map.state.camera.bearing == 0 && map.state.camera.pitch == 0)
      #expect(
        await MapWindow.until {
          abs(renderer.mapView.direction) < 0.01 && renderer.mapView.camera.pitch < 0.01
        }, "MapLibre's own reset of north keeps the pitch; the engine's turns it to 0")
      #expect(abs(renderer.mapView.zoomLevel - 14) < 0.01)
      #expect(throws: MapError.self) { try map.ease(to: CameraTarget(zoom: .nan)) }
      window.isHidden = true
    }

    @Test("a fit lands where cameraForBounds frames the box on the view's own canvas, facing north")
    func fit() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.jump(to: CameraTarget(bearing: 45))
      let box: [Double] = [6.8, 45.8, 6.95, 45.9]

      try map.fitBounds(
        box, with: CameraFit(padding: PixelPadding(24), maxZoom: 15, duration: .zero))
      let size = renderer.mapView.bounds.size
      let expected = try #require(
        cameraForBounds(
          box, canvas: [Double(size.width), Double(size.height)], padding: PixelPadding(24),
          maxZoom: 15, window: map.state.zoomBounds))
      #expect(abs(map.state.camera.zoom - expected.zoom) < 1e-9)
      #expect(map.state.camera.bearing == 0)
      #expect(
        await MapWindow.until {
          abs(renderer.mapView.zoomLevel - expected.zoom) < 1e-3
            && abs(renderer.mapView.centerCoordinate.longitude - expected.center[0]) < 1e-6
            && abs(renderer.mapView.centerCoordinate.latitude - expected.center[1]) < 1e-6
            && abs(renderer.mapView.direction) < 0.01
        }, "\(Self.shown(renderer)), expected \(expected)")
      let shown = renderer.mapView.visibleCoordinateBounds
      #expect(
        shown.sw.longitude <= 6.8 && shown.ne.longitude >= 6.95 && shown.sw.latitude <= 45.8
          && shown.ne.latitude >= 45.9, "\(Self.shown(renderer))")
      window.isHidden = true
    }

    @Test("a point query answers what the map's own layers drew there, topmost first, as features")
    func queries() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.jump(to: CameraTarget(center: [6.86, 45.83], zoom: 14, bearing: 0, pitch: 0))
      Self.drawTrail(on: map)
      let point = map.project([6.86, 45.83])
      #expect(point.count == 2 && point.allSatisfy { $0.isFinite }, "\(point)")
      #expect(await MapWindow.until { map.features(at: point).count >= 2 })

      let found = map.features(at: point)
      #expect(found.map(\.layer) == ["huts", "route"], "the waypoint above its leg")
      let hut = try #require(found.first)
      #expect(hut.properties["waypoint_id"] == "hut")
      #expect(hut.properties["beds"] == 24)
      #expect(hut.properties["kinds"] == nil, "a property holding a list is left out")
      #expect(hut.sourceLayer == nil, "a GeoJSON source has no source layer")
      guard case .point(let drawn) = hut.geometry else {
        Issue.record("the waypoint is no point: \(hut.geometry)")
        return
      }
      #expect(abs(drawn.coordinates[0] - 6.86) < 1e-6)
      #expect(map.itineraries(at: point).map(\.layer) == ["huts", "route"])
      #expect(map.pois(at: point).isEmpty)
      #expect(map.zones(at: point).isEmpty)
      let back = map.unproject(point)
      #expect(abs(back[0] - 6.86) < 1e-6 && abs(back[1] - 45.83) < 1e-6, "\(back)")
      // The engine holds the surface it is drawn on weakly, as `MapView`'s coordinator keeps it.
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    @Test("a tap is told, and again with the features it landed on; a long press and a hover too")
    func events() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      try map.jump(to: CameraTarget(center: [6.86, 45.83], zoom: 14, bearing: 0, pitch: 0))
      Self.drawTrail(on: map)
      let point = map.project([6.86, 45.83])
      #expect(await MapWindow.until { map.features(at: point).count >= 2 })
      let told = Told(map)
      let at = CGPoint(x: point[0], y: point[1])

      renderer.tapped(at: at)
      renderer.pressed(at: at)
      renderer.hovered(at: at)
      #expect(
        await MapWindow.until {
          told.events.contains { if case .featureHover = $0 { true } else { false } }
        }, "a hover is told at the next frame MapLibre's view draws")
      renderer.left(at: CGPoint(x: -1, y: point[1]))
      #expect(await MapWindow.until { told.events.count >= 5 }, "\(told.events)")

      guard told.events.count == 5,
        case .tap(let tap) = told.events[0],
        case .featureTap(let tapped, let features) = told.events[1],
        case .longTap(let pressed) = told.events[2],
        case .featureHover(_, let hovered) = told.events[3],
        case .featureHover(_, let left) = told.events[4]
      else {
        Issue.record("\(told.events)")
        return
      }
      #expect(abs(tap.position[0] - 6.86) < 1e-6 && tap.point == point)
      #expect(tapped == tap.position)
      #expect(features.map(\.layer) == ["huts", "route"])
      #expect(abs(pressed.position[1] - 45.83) < 1e-6)
      #expect(hovered.map(\.layer) == ["huts", "route"])
      #expect(left.isEmpty, "a pointer leaving is told with no feature")
      window.isHidden = true
    }

    /// Stamping is the Tile API's catalogue, for a map's client, holding one classic overlay the
    /// server stamps, `snow-depth`, drawn from the stub's tiles under `directory`, a directory no
    /// run asked for before, since MapLibre keeps the tiles it fetched in a cache of its own.
    private struct Stamping: HTTPExchange {
      let directory: String

      func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
        let body = """
          {"data": {
            "elevation": {"id": "e", "tile_size": 512, "url": "https://tiles.example.test/elevation.json"},
            "itineraries": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "i", "locales": {}, "slug": "itineraries", "sources": []},
            "zones": {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": false}},
              "content_type": "application/x-protobuf", "id": "z", "locales": {}, "slug": "zones", "sources": []},
            "overlays": [{"id": "c", "locales": {}, "slug": "conditions", "children": [
              {"capabilities": {"client": {"timestamp": false}, "server": {"timestamp": true}},
                "content_type": "application/x-protobuf", "id": "snow-depth", "locales": {},
                "slug": "snow-depth", "sources": [{"id": "snow-depth", "layers": [{"id": "snow-fill",
                  "key": "snow", "layout": null, "paint": null, "source_layer": "snow", "type": "fill",
                  "zoom_max": 22, "zoom_min": 0}],
                  "tiles": ["https://tiles.example.test/v1/overlays/\(directory)/{z}/{x}/{y}"],
                  "type": "vector", "zoom_max": 14, "zoom_min": 0}]}]}],
            "terrains": []}}
          """
        return ExchangeResponse(
          status: 200, headers: ["Content-Type": "application/json"],
          body: ExchangeBody(Data(body.utf8)))
      }
    }

    /// overlayTiles is every tile request MapLibre sent for the overlay under `directory` since the
    /// `from`th request the stub was sent, each its query, empty for none.
    private static func overlayTiles(_ directory: String, from: Int) -> [String] {
      StubTileAPI.requests.dropFirst(from).compactMap { request in
        guard let url = request.url, url.path.contains("/overlays/\(directory)/") else {
          return nil
        }
        return url.query ?? ""
      }
    }

    @Test(
      "a pin swaps the stamped overlay's tiles in place, its layer standing, and a switch keeps them"
    )
    func stampedOverlay() async throws {
      _ = StubTileAPI.installed
      let directory = UUID().uuidString
      let client = try Mountaya(
        credential: .publishable(key: "pk_test_a"),
        baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)),
        exchange: Stamping(directory: directory))
      let map = MapEngine(
        client: client, style: StubTileAPI.styleUrl,
        camera: CameraPose(center: [6.86, 45.83], zoom: 10, pitch: 0, bearing: 0))
      let (renderer, window) = try await Self.ready(map)
      try await map.setOverlay("snow-depth")
      #expect(
        await MapWindow.until { Self.overlayTiles(directory, from: 0).contains("") },
        "the manifest's own addresses with none pinned")
      let drawn = Self.ownLayers(renderer)
      #expect(drawn == ["snow-fill"])

      // A pin asks the overlay again for its instant, its layer where it stood.
      let stamp = "timestamp=2026-03-14T09%3A00%3A00.000Z"
      var sent = StubTileAPI.requests.count
      map.setInstant(Date(timeIntervalSince1970: 1_773_478_800))
      #expect(
        await MapWindow.until { Self.overlayTiles(directory, from: sent).contains(stamp) },
        "\(Self.overlayTiles(directory, from: sent))")
      #expect(Self.ownLayers(renderer) == drawn)

      // A base map switched to draws the overlay for the pin, elsewhere, where no tile was asked.
      sent = StubTileAPI.requests.count
      let dark = try #require(
        URL(string: "https://tiles.example.test/v1/terrains/outdoor/dark/style"))
      map.setStyle(dark)
      try map.jump(to: CameraTarget(center: [-71.06, 42.36], zoom: 9))
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == dark && Self.ownLayers(renderer) == drawn
            && Self.overlayTiles(directory, from: sent).contains(stamp)
        }, "\(Self.overlayTiles(directory, from: sent))")
      #expect(
        !Self.overlayTiles(directory, from: sent).contains(""),
        "the switch asks for the addresses asked for, never the manifest's own")

      // None pinned draws the manifest's own addresses again.
      map.setInstant(nil)
      #expect(await MapWindow.until { renderer.drawn == map.state })
      sent = StubTileAPI.requests.count
      try map.jump(to: CameraTarget(center: [139.69, 35.68], zoom: 9))
      #expect(
        await MapWindow.until { Self.overlayTiles(directory, from: sent).contains("") },
        "\(Self.overlayTiles(directory, from: sent))")
      window.isHidden = true
      _ = renderer
    }

    @Test("a tile of the map's own refused a 402 is told as a refusal of access, which stands")
    func accessRefused() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)

      map.addSource(
        MapSource(
          id: "refused",
          kind: .vector(
            tiles: ["https://tiles.example.test/v1/refused/{z}/{x}/{y}"],
            zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      map.addLayer(
        MapLayer(
          id: "refused-lines", type: .line, source: "refused", sourceLayer: "lines",
          rank: LayerRank.overlay.rank))

      #expect(await MapWindow.until { map.state.isAccessRequired })
      #expect(
        await MapWindow.until {
          told.events.contains {
            if case .accessRefused(402, let url) = $0 {
              url.hasPrefix("https://tiles.example.test/v1/refused/")
            } else {
              false
            }
          }
        }, "\(told.events)")
      #expect(
        !told.events.contains { if case .failure = $0 { true } else { false } },
        "a refusal is never also a failure")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// unseenStyle is a style under `directory` of the stub Tile API at an address no run asked for
    /// before: MapLibre keeps the styles it fetched in a cache of its own, which outlives a run and
    /// answers a style it holds with no request.
    private static func unseenStyle(under directory: String) throws -> URL {
      let address = "https://tiles.example.test/v1/terrains/\(directory)/\(UUID().uuidString)/style"
      return try #require(URL(string: address))
    }

    /// sessionEngine is a map over a client of the stub Tile API whose session token is `token`'s
    /// answer at each read, showing the stub's base map.
    private static func sessionEngine(_ token: @escaping @Sendable () -> String?) throws
      -> MapEngine
    {
      _ = StubTileAPI.installed
      let client = try Mountaya(
        credential: .publishable(key: "pk_test_session", sessionToken: .function(token)),
        language: "fr", baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)))
      return MapEngine(
        client: client, style: StubTileAPI.styleUrl,
        camera: CameraPose(center: [6.86, 45.83], zoom: 10, pitch: 0, bearing: 0))
    }

    /// An organization that requires a session refuses the key alone, and the first session token
    /// lands as the style asked for under the key alone reaches the Tile API: the refusal is of a
    /// credential the map no longer sends.
    @Test("a style refused under a credential no longer sent is asked for again, and nothing told")
    func styleRefusedStale() async throws {
      let before = StubTileAPI.requests.count
      let session = try Self.unseenStyle(under: "session")
      let map = try Self.sessionEngine {
        StubTileAPI.requests.dropFirst(before).contains {
          $0.url?.path.contains("/session/") ?? false
        } ? "sess_landed" : nil
      }
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(id: "route", type: .line, source: "trail", rank: LayerRank.itineraryLine.rank))

      map.setStyle(session)
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == session && Self.ownLayers(renderer) == ["route"]
        }, "the style asked for is drawn, the map's content on it: \(told.events)")
      let asked = StubTileAPI.requests.dropFirst(before).filter { $0.url == session }
      #expect(
        asked.map { $0.value(forHTTPHeaderField: "X-Session-Token") } == [nil, "sess_landed"],
        "asked for again once, under the token the client sends")
      #expect(map.state.style == session)
      #expect(!map.state.isAccessRequired)
      #expect(told.events.isEmpty, "\(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// Every read finds a token other than the one before, so each refusal is of a credential the
    /// client no longer sends: the style is asked for again once, then given up, told to nobody.
    @Test("a style refused so again gives the map back the one shown, asked for again once an ask")
    func styleRefusedStaleTwice() async throws {
      let before = StubTileAPI.requests.count
      let revoked = try Self.unseenStyle(under: "revoked")
      let reads = OSAllocatedUnfairLock(initialState: 0)
      let map = try Self.sessionEngine {
        reads.withLock { reads in
          reads += 1
          return "sess_\(reads)"
        }
      }
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)

      map.setStyle(revoked)
      #expect(
        await MapWindow.until {
          map.state.style == StubTileAPI.styleUrl
            && StubTileAPI.requests.dropFirst(before).filter { $0.url == revoked }.count == 2
        }, "\(told.events)")
      // Long enough for a refusal or a failure told late to be heard.
      try await Task.sleep(for: .milliseconds(300))
      #expect(StubTileAPI.requests.dropFirst(before).filter { $0.url == revoked }.count == 2)
      #expect(told.events.isEmpty, "a refusal told to nobody is no failure either: \(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// isRefused tells whether `event` is a refusal of access.
    private static func isRefused(_ event: MapEvent) -> Bool {
      if case .accessRefused = event { true } else { false }
    }

    /// isFailure tells whether `event` is a failure.
    private static func isFailure(_ event: MapEvent) -> Bool {
      if case .failure = event { true } else { false }
    }

    /// MapLibre tells a style that did not arrive apart from its answer, which the request hook
    /// heard first: a refusal is told once, as the tile's is, and the map goes back to the one
    /// shown.
    @Test(
      "a style refused access under the credential sent is told as that refusal alone",
      arguments: [("revoked", 401), ("refused", 402)])
    func styleRefused(under directory: String, status: Int) async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      let style = try Self.unseenStyle(under: directory)
      let refused = MapEvent.accessRefused(status: status, url: style.absoluteString)

      map.setStyle(style)
      #expect(
        await MapWindow.until {
          map.state.style == StubTileAPI.styleUrl && told.events.contains(refused)
        }, "\(told.events)")
      // Long enough for a refusal or a failure told late to be heard.
      try await Task.sleep(for: .milliseconds(300))
      #expect(told.events.filter(Self.isRefused) == [refused], "\(told.events)")
      #expect(!told.events.contains(where: Self.isFailure), "\(told.events)")
      #expect(map.state.style == StubTileAPI.styleUrl, "the base map shown is kept")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// The hook hears the style's answer, a 500, before MapLibre tells the style did not arrive:
    /// the failure is told once, as the hook told it, with its status.
    @Test("a style failing for any other reason is told once as a failure, the base map shown kept")
    func styleBroken() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      let style = try Self.unseenStyle(under: "broken")

      map.setStyle(style)
      #expect(
        await MapWindow.until {
          map.state.style == StubTileAPI.styleUrl
            && told.events.contains(.failure(url: style.absoluteString, status: 500))
        }, "\(told.events)")
      // Long enough for a failure told late to be heard.
      try await Task.sleep(for: .milliseconds(300))
      #expect(
        told.events.filter(Self.isFailure) == [.failure(url: style.absoluteString, status: 500)],
        "told once: \(told.events)")
      #expect(!told.events.contains(where: Self.isRefused), "\(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// A style on a host that does not answer reaches the hook with no answer, which tells it, and
    /// MapLibre then tells the style did not arrive.
    @Test("a style that reaches no answer is told once as a failure, the base map shown kept")
    func styleOffline() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      let style = try #require(
        URL(string: "https://offline.hook.invalid/v1/terrains/outdoor/\(UUID().uuidString)/style"))
      let failure = MapEvent.failure(url: style.absoluteString, status: nil)

      map.setStyle(style)
      #expect(
        await MapWindow.until {
          map.state.style == StubTileAPI.styleUrl && told.events.contains(failure)
        }, "\(told.events)")
      // Long enough for a failure told late to be heard.
      try await Task.sleep(for: .milliseconds(300))
      #expect(told.events.filter(Self.isFailure) == [failure], "told once: \(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// MapLibre repeats an offline tile on its own schedule, and the hook hears each with no
    /// answer: told as a failure at the address the map asked for, never as a refusal.
    @Test("a tile of the map's own that reaches no answer is told as a failure")
    func tileOffline() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)

      map.addSource(
        MapSource(
          id: "offline",
          kind: .vector(
            tiles: ["https://offline.hook.invalid/v1/zones/{z}/{x}/{y}"],
            zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      map.addLayer(
        MapLayer(
          id: "offline-lines", type: .line, source: "offline", sourceLayer: "lines",
          rank: LayerRank.overlay.rank))

      #expect(
        await MapWindow.until {
          told.events.contains {
            if case .failure(let url, nil, _) = $0 {
              url.hasPrefix("https://offline.hook.invalid/v1/zones/")
            } else {
              false
            }
          }
        }, "\(told.events)")
      #expect(!told.events.contains(where: Self.isRefused), "\(told.events)")
      #expect(!map.state.isAccessRequired)
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// MapLibre asks for a style as it is handed one, on a thread of its own, so a map handed its
    /// style before the hook shows it may send the style's first request with no credential and
    /// unrecorded: the setter of MapLibre's map, watched, signs a request to the style the moment
    /// it is asked, which carries the map's credential only where the hook shows the map by then.
    @Test("MapLibre is asked for a map's style only once the request hook shows the map")
    func styleAfterTheHook() throws {
      _ = StubTileAPI.installed
      let style = try Self.unseenStyle(under: "hooked")
      let client = try Mountaya(
        credential: .publishable(key: "pk_test_hooked"), language: "fr",
        baseUrls: BaseURLs(tiles: try #require(StubTileAPI.tiles)))
      let map = MapEngine(client: client, style: style)

      StyleAsks.watch(style)
      let renderer = MapRenderer(engine: map, onReady: nil)
      StyleAsks.watch(nil)

      #expect(StyleAsks.signed == ["pk_test_hooked"], "asked once, under the map's credential")
      map.close()
      withExtendedLifetime(renderer) {}
    }

    /// The stub redirects a request under `/bounce/` within the Tile API, and one under `/moved/`
    /// to another host. A failure names the address the map asked for, not the one a redirect led
    /// to, since it is that address which names the style asked for or lies under a source's
    /// templates.
    @Test(
      "a style redirected, then refused access, is told as that refusal at its own address alone",
      arguments: ["bounce", "moved"])
    func styleRedirectedRefused(through hop: String) async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      let style = try Self.unseenStyle(under: "\(hop)/revoked")
      let refused = MapEvent.accessRefused(status: 401, url: style.absoluteString)

      map.setStyle(style)
      #expect(
        await MapWindow.until {
          map.state.style == StubTileAPI.styleUrl && told.events.contains(refused)
        }, "\(told.events)")
      // Long enough for a refusal or a failure told late to be heard.
      try await Task.sleep(for: .milliseconds(300))
      #expect(told.events.filter(Self.isRefused) == [refused], "\(told.events)")
      #expect(!told.events.contains(where: Self.isFailure), "\(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    @Test(
      "of two maps, a tile redirected, then refused, is told to the map whose source asked for it",
      arguments: ["bounce", "moved"])
    func tileRedirectedRefused(through hop: String) async throws {
      let alpine = try Self.engine()
      let coast = try Self.engine()
      let toldAlpine = Told(alpine)
      let toldCoast = Told(coast)
      let (first, second, window) = try await Self.twoReady(upper: alpine, lower: coast)
      // Apart from the tiles other tests read back from what the stub recorded.
      let tiles = "https://tiles.example.test/v1/redirected/\(hop)/revoked/\(UUID().uuidString)/"

      alpine.addSource(
        MapSource(
          id: "refused",
          kind: .vector(tiles: [tiles + "{z}/{x}/{y}"], zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      alpine.addLayer(
        MapLayer(
          id: "refused-lines", type: .line, source: "refused", sourceLayer: "lines",
          rank: LayerRank.overlay.rank))

      // The refusal names the address the source's templates hold, which names the source.
      #expect(
        await MapWindow.until {
          toldAlpine.events.contains {
            if case .accessRefused(401, let url) = $0 { url.hasPrefix(tiles) } else { false }
          }
        }, "\(toldAlpine.events)")
      #expect(alpine.state.isAccessRequired)
      // What the other map would be told is told in the same turns.
      try await Task.sleep(for: .milliseconds(300))
      #expect(
        toldAlpine.events.allSatisfy {
          if case .accessRefused(_, let url) = $0 { url.hasPrefix(tiles) } else { true }
        }, "\(toldAlpine.events)")
      #expect(!toldAlpine.events.contains(where: Self.isFailure), "\(toldAlpine.events)")
      #expect(!toldCoast.events.contains(where: Self.isRefused), "\(toldCoast.events)")
      #expect(!coast.state.isAccessRequired)
      withExtendedLifetime((first, second)) { window.isHidden = true }
    }

    @Test(
      "a style redirected to one served is drawn, the map's content on it",
      arguments: ["bounce", "moved"])
    func styleRedirected(through hop: String) async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(id: "route", type: .line, source: "trail", rank: LayerRank.itineraryLine.rank))
      let style = try Self.unseenStyle(under: hop)

      map.setStyle(style)
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == style && Self.ownLayers(renderer) == ["route"]
        }, "\(told.events)")
      #expect(map.state.style == style)
      #expect(!told.events.contains(where: Self.isFailure), "\(told.events)")
      #expect(!told.events.contains(where: Self.isRefused), "\(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// The renderer draws the states the engine reports a turn later, so MapLibre may tell a style
    /// loaded once a later base map is asked for. Its telling is held back here, the map's delegate
    /// let go while the first style loads, and played between the later ask and its drawing.
    @Test("a style told loaded once a later one is asked for is given back as that one is refused")
    func styleLoadedLate() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      let first = try Self.unseenStyle(under: "first")
      renderer.mapView.delegate = nil
      map.setStyle(first)
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == first && renderer.mapView.style != nil
        }, "the first style loads in MapLibre")
      renderer.mapView.delegate = renderer

      let refused = try Self.unseenStyle(under: "revoked")
      map.setStyle(refused)
      renderer.mapView(renderer.mapView, didFinishLoading: try #require(renderer.mapView.style))

      #expect(
        await MapWindow.until {
          map.state.style == first
            && told.events.contains(.accessRefused(status: 401, url: refused.absoluteString))
        }, "the style that loaded is given back: \(told.events)")
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == first && renderer.mapView.style != nil
        }, "and drawn")
      #expect(!told.events.contains(where: Self.isFailure), "\(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    @Test("a base map asked for past another before that one loads is the one shown")
    func styleSwitchedFast() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let told = Told(map)
      map.addSource(MapSource(id: "trail", kind: .geoJson(Self.pins)))
      map.addLayer(
        MapLayer(id: "route", type: .line, source: "trail", rank: LayerRank.itineraryLine.rank))
      let first = try Self.unseenStyle(under: "first")
      let second = try Self.unseenStyle(under: "second")

      map.setStyle(first)
      map.setStyle(second)
      #expect(
        await MapWindow.until {
          renderer.mapView.styleURL == second && Self.ownLayers(renderer) == ["route"]
        }, "\(told.events)")
      #expect(map.state.style == second)
      // The second is the base map shown: one refused after it gives it back.
      map.setStyle(try Self.unseenStyle(under: "revoked"))
      #expect(
        await MapWindow.until {
          map.state.style == second && renderer.mapView.styleURL == second
            && Self.ownLayers(renderer) == ["route"]
        }, "\(told.events)")
      #expect(!told.events.contains(where: Self.isFailure), "\(told.events)")
      withExtendedLifetime(renderer) { window.isHidden = true }
    }

    /// MapLibre shows a compass of its own on a rotated map, which would stand beside the one
    /// `MapControls(compass:)` draws: the renderer shows none, and leaves the credits where they
    /// are.
    @Test("a rotated map shows none of MapLibre's own compass, and its credits at the bottom right")
    func noOwnCompass() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)

      try map.jump(to: CameraTarget(center: [6.86, 45.83], zoom: 10, bearing: 90, pitch: 0))
      #expect(await MapWindow.until { abs(renderer.mapView.direction - 90) < 0.5 })
      // MapLibre fades its compass in as the map turns.
      try await Task.sleep(for: .milliseconds(600))

      let compass = renderer.mapView.compassView
      #expect(
        compass.isHidden || compass.alpha == 0 || compass.window == nil,
        "MapLibre's compass shows: hidden \(compass.isHidden), alpha \(compass.alpha)")
      #expect(renderer.mapView.attributionButtonPosition == .bottomRight)
      #expect(!renderer.mapView.attributionButton.isHidden)
      window.isHidden = true
    }

    /// twoReady draws `upper` and `lower` one above the other in a window, as an app shows two
    /// maps, and returns their renderers once both styles are loaded.
    private static func twoReady(upper: MapEngine, lower: MapEngine) async throws -> (
      MapRenderer, MapRenderer, UIWindow
    ) {
      let loaded = OSAllocatedUnfairLock(initialState: 0)
      let first = MapRenderer(engine: upper, onReady: { _ in loaded.withLock { $0 += 1 } })
      let second = MapRenderer(engine: lower, onReady: { _ in loaded.withLock { $0 += 1 } })
      let both = UIView()
      first.mapView.frame = CGRect(x: 0, y: 0, width: 390, height: 422)
      second.mapView.frame = CGRect(x: 0, y: 422, width: 390, height: 422)
      both.addSubview(first.mapView)
      both.addSubview(second.mapView)
      let window = MapWindow.showing(both)
      try #require(await MapWindow.until { loaded.withLock { $0 } == 2 }, "the styles never loaded")
      return (first, second, window)
    }

    /// isRefusal tells whether `event` is a refusal of access at an address under `prefix`.
    private static func isRefusal(_ event: MapEvent, under prefix: String) -> Bool {
      if case .accessRefused(402, let url) = event { url.hasPrefix(prefix) } else { false }
    }

    @Test("of two maps, a refusal of one's own tiles is told to it, and the other hears nothing")
    func refusalOfOneOfTwo() async throws {
      let alpine = try Self.engine()
      let coast = try Self.engine()
      let toldAlpine = Told(alpine)
      let toldCoast = Told(coast)
      let (first, second, window) = try await Self.twoReady(upper: alpine, lower: coast)

      alpine.addSource(
        MapSource(
          id: "refused",
          kind: .vector(
            tiles: ["https://tiles.example.test/v1/refused/alpine/{z}/{x}/{y}"],
            zoom: ZoomBounds(minZoom: 0, maxZoom: 14))))
      alpine.addLayer(
        MapLayer(
          id: "refused-lines", type: .line, source: "refused", sourceLayer: "lines",
          rank: LayerRank.overlay.rank))

      #expect(
        await MapWindow.until {
          toldAlpine.events.contains {
            Self.isRefusal($0, under: "https://tiles.example.test/v1/refused/alpine/")
          }
        }, "\(toldAlpine.events)")
      #expect(alpine.state.isAccessRequired)
      // What the other map would be told is told in the same turns.
      try await Task.sleep(for: .milliseconds(300))
      #expect(!coast.state.isAccessRequired)
      #expect(!toldCoast.events.contains { Self.isRefusal($0, under: "") })
      withExtendedLifetime((first, second)) { window.isHidden = true }
    }

    /// A base map's sources name their tiles in a style the renderer cannot read back, so the map
    /// claims them by its style's directory, where a Mountaya terrain serves its tiles.
    @Test("of two maps, a refusal of one's base map is told to the map whose style names it")
    func baseMapRefusalOfOneOfTwo() async throws {
      let closed = try Self.engine(
        style: URL(string: "https://tiles.example.test/v1/terrains/closed/light/style"))
      let open = try Self.engine()
      let toldClosed = Told(closed)
      let toldOpen = Told(open)
      let (first, second, window) = try await Self.twoReady(upper: closed, lower: open)

      #expect(
        await MapWindow.until {
          toldClosed.events.contains {
            Self.isRefusal($0, under: "https://tiles.example.test/v1/terrains/closed/light/")
          }
        }, "\(toldClosed.events)")
      #expect(closed.state.isAccessRequired)
      try await Task.sleep(for: .milliseconds(300))
      #expect(!toldOpen.events.contains { Self.isRefusal($0, under: "") }, "\(toldOpen.events)")
      #expect(!open.state.isAccessRequired)
      withExtendedLifetime((first, second)) { window.isHidden = true }
    }

    @Test("the map credits Mountaya first, then each source it draws, and its button lists them")
    func credits() async throws {
      let map = try Self.engine()
      let (renderer, window) = try await Self.ready(map)
      let elsewhere =
        #"<a href="https://elsewhere.example.test/" target="_blank">&copy; Elsewhere</a>"#

      #expect(map.credits == [mountayaCredit, elsewhere], "\(map.credits)")
      map.addSource(
        MapSource(
          id: "trails", kind: .geoJson(Self.pins), attribution: "&copy; Trails of the Alps"))
      #expect(
        map.credits == [mountayaCredit, elsewhere], "a source no layer draws is not credited")
      map.addLayer(
        MapLayer(id: "trail-lines", type: .line, source: "trails", rank: 50))
      #expect(map.credits == [mountayaCredit, elsewhere, "&copy; Trails of the Alps"])

      let actions =
        renderer.mapView.attributionButton.actions(
          forTarget: renderer, forControlEvent: .touchUpInside) ?? []
      #expect(actions == ["showCredits"], "the credit button opens the map's own credits")
      let sheet = creditSheet(map.credits) { _ in }
      #expect(
        sheet.actions.map(\.title) == [
          "\u{A9} Mountaya", "\u{A9} Elsewhere", "\u{A9} Trails of the Alps", "OK",
        ])
      window.isHidden = true
    }

    /// showsWithin tells whether everything the map shows lies within `lock`,
    /// `[west, south, east, north]`, to a millionth of a degree.
    private static func showsWithin(_ lock: [Double], in renderer: MapRenderer) -> Bool {
      let shown = renderer.mapView.visibleCoordinateBounds
      let tolerance = 1e-6
      return shown.sw.longitude >= lock[0] - tolerance && shown.sw.latitude >= lock[1] - tolerance
        && shown.ne.longitude <= lock[2] + tolerance && shown.ne.latitude <= lock[3] + tolerance
    }

    /// shown is the box the map shows, `[west, south, east, north]`, and its zoom, for a message.
    private static func shown(_ renderer: MapRenderer) -> String {
      let shown = renderer.mapView.visibleCoordinateBounds
      let box = [shown.sw.longitude, shown.sw.latitude, shown.ne.longitude, shown.ne.latitude]
      return "\(box) at \(renderer.mapView.zoomLevel)"
    }

    private static func number(_ expression: NSExpression) -> Double? {
      (expression.constantValue as? NSNumber)?.doubleValue
    }

    /// label is a symbol layer's label as MapLibre's style document writes it, in JSON.
    private static func label(_ layer: MLNSymbolStyleLayer) -> String {
      guard
        let data = try? JSONSerialization.data(
          withJSONObject: layer.text.mgl_jsonExpressionObject, options: [.sortedKeys])
      else { return "" }
      return String(decoding: data, as: UTF8.self)
    }
  }
}

extension MLNMapView {
  /// recordedStyleUrl stands for MapLibre's own `setStyleURL:` while `StyleAsks` watches a style:
  /// it signs a request to the style watched as the map is asked for it, then sets the style, its
  /// implementation, once exchanged, MapLibre's own setter's.
  @objc fileprivate func recordedStyleUrl(_ url: URL?) {
    if let url, url == MapLibreSuites.MapRendererTests.StyleAsks.watched {
      let signed = MapRequestHook.shared.willSend(NSMutableURLRequest(url: url))
      MapLibreSuites.MapRendererTests.StyleAsks.signed.append(
        signed.value(forHTTPHeaderField: "X-API-Key"))
    }
    recordedStyleUrl(url)
  }
}
