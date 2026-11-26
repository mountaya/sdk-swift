import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo

#if os(iOS) && !targetEnvironment(macCatalyst)
  import MapLibre
  import SwiftUI
#endif

/// Elements reads the map product as an app does: the map's state and engine on every platform,
/// the glyph set its sprites draw from and the paint it draws in, its layers ranked and patched,
/// its content drawn by id and by name and framed, the base map switched, the layers catalogue,
/// overlays and enrichments, layers and concepts shown and hidden, restricted stretches, Data API
/// results and geometry slots, markers with their glyph, the camera moved, fitted, stepped and held
/// to its limits, the device located through a geolocation of the app's own, point queries and the
/// events the map tells, its credits, a waypoint placed by the magnet, an app's test driving the
/// engine on the scripted surface, and, in an iOS build with the Elements trait, the view over
/// MapLibre with its ready, tap and camera callbacks, and a glyph drawn in SwiftUI.
enum Elements {
  /// Here is a geolocation of an app's own, answering the fix its own location stack holds.
  struct Here: Geolocation {
    func locate() async -> GeolocationFix {
      .located(position: [6.8652, 45.9237], accuracyMeters: 30)
    }

    func permission() async -> GeolocationPermission { .granted }
  }

  /// readKind reads every kind of a map's refusal, as a client compiled at the 6.2 floor must,
  /// beside the default a newer compiler reads for a kind this build does not know.
  static func readKind(_ error: MapError) {
    switch error.kind {
    case .layerNotFound, .terrainNotFound, .markerNotFound: _ = error.name
    case .positionRefused, .maxBoundsRefused, .zoomBoundsRefused, .numberRefused:
      _ = error.description
    case .fixRefused(let reason): _ = reason.rawValue
    case .closed: _ = error.description
    case .typeRefused, .overlayNotFound, .kindMismatch, .analysisNotFound, .noInput:
      _ = error.name
    @unknown default: break
    }
  }

  /// draw holds a map's state with the engine, as an app that draws its own map does.
  @MainActor
  static func draw() async throws -> MapState {
    let mountaya = try Mountaya(
      credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"), language: "fr")
    _ = mountaya.baseUrls.tiles
    var paint = MapPaint.standard
    paint.itinerary.casingColor = "#1b1b1b"
    paint.layerRanks["acme_avalanche"] = LayerRank.poi.rank + 2
    let map = MapEngine(
      client: mountaya,
      terrainVariant: .light,
      camera: CameraPose(center: [6.8652, 45.9237], zoom: 12, pitch: 0, bearing: 0),
      paint: paint,
      glyphs: GlyphSet(chaining: [.marker]) ?? .marker,
      geolocation: Here(),
      transformRequest: { request in request })
    _ = (map.glyphs.name, map.paint.itinerary.casingColor)
    _ = MapEngine(client: mountaya, geolocation: InertGeolocation())
    _ = MapEngine(client: mountaya, geolocation: DeviceGeolocation())
    try await map.setTerrainVariant(.dark)
    try await map.setTerrain("outdoor")
    _ = (map.state.terrain, map.state.terrainVariant)
    // The organization the map's key was minted for, read once per key and origin and shared.
    let organization: RestSchema.Organization? = try? await map.loadOrganization()
    _ = (organization?.white_label, map.organization?.white_label)
    // Where the read stands, in the contract's five states, and the mark's frame kept clear.
    let keepsClear: Bool
    switch map.organizationRead {
    case .waiting, .failed, .timedOut, .noKey: keepsClear = true
    case .answered(let whiteLabel): keepsClear = !whiteLabel
    }
    _ = (keepsClear, watermarkWidth, watermarkHeight, watermarkInset, watermarkClearance)
    map.setStyle(URL(string: "https://tiles.mountaya.com/v1/terrains/outdoor/light/style"))
    try map.jump(to: CameraTarget(center: [6.9, 45.9], zoom: 13, bearing: 90, pitch: 45))
    try map.ease(to: CameraTarget(zoom: 14))
    try map.fly(to: CameraTarget(center: [6.86, 45.83]))
    try map.fitBounds(
      [6.8, 45.8, 6.95, 45.9],
      with: CameraFit(padding: PixelPadding(48), maxZoom: 15, duration: .milliseconds(300)))
    map.zoomIn()
    map.zoomOut()
    map.resetNorth()
    map.easeIntoZoomRange(ZoomBounds(minZoom: 10, maxZoom: 14))
    if let here = try? await map.locate() {
      _ = here
    }
    map.setLabelLanguage(.de)
    _ = map.credits

    map.addSource(MapSource(id: "trail", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
    map.addLayer(
      MapLayer(
        id: "route", type: .line, source: "trail",
        rank: LayerRank.itineraryLine.rank, paint: ["line-color": "#e64980", "line-width": 4]))
    try map.editLayer("route", paint: ["line-color": "#228be6", "line-width": nil])
    do {
      try map.editLayer("gone", layout: ["visibility": "none"])
    } catch {
      readKind(error)
    }
    try map.addMarker(
      MapMarker(
        id: "hut", position: [6.86, 45.83, 1_834], color: "#e64980", glyph: "hut", label: "Refuge"))
    try map.editMarker(
      "hut", position: [6.87, 45.84], color: nil, glyph: "mountain", label: "Refuge du Col")
    map.removeMarker("hut")
    map.clearMarkers()
    try map.setMaxBounds([6.7, 45.7, 7.1, 46.1])
    try map.setMaxBounds(nil)
    let effective = effectiveZoomBounds(zoomMin: 4, zoomMax: 16)
    try map.setZoomBounds(min: .zoom(effective.minZoom), max: .zoom(effective.maxZoom))
    try map.setZoomBounds(min: 8, max: 12.5)
    try map.setZoomBounds(max: .released)
    try map.setZoomBounds(min: .released, max: .kept)
    _ = refusesMaxBounds([5, 45, 7, 45])
    map.setActiveSegments([[[6.85, 45.83], [6.87, 45.83]]])
    try map.beginWaypointEdit("w1", at: nil)
    try map.placeWaypoint(
      at: [6.86, 45.831], through: ScreenProjection(point: { $0 }, position: { $0 }))
    if let edit = map.endWaypointEdit() {
      _ = (edit.waypointId, edit.position, edit.isSnapped)
    }
    do {
      try map.editMarker("gone", label: "?")
    } catch {
      readKind(error)
    }
    let tap = MapTap(position: [6.86, 45.83], point: [10, 20], marker: "hut")
    _ = (tap.position, tap.point, tap.marker)
    let found: [QueriedFeature] =
      map.features(at: [10, 20]) + map.pois(at: [10, 20]) + map.zones(at: [10, 20])
      + map.itineraries(at: [10, 20])
    for feature in found {
      switch feature.id {
      case .number(let number)?: _ = number
      case .string(let text)?: _ = text
      case nil: break
      }
      _ = (feature.properties, feature.geometry, feature.layer, feature.sourceLayer)
    }
    _ = (map.project([6.86, 45.83]), map.unproject([10, 20]))
    if let elevation = try? await map.elevation(at: [6.86, 45.83]) {
      _ = elevation
    }
    try await content(on: map, from: mountaya)
    try await results(on: map)
    map.removeLayer("route")
    map.removeSource("trail")
    let layer = MapLayer(
      TileSchema.TileLayer(
        id: "l", key: "k", layout: nil, paint: nil, source_layer: "fills",
        type: .fill, zoom_max: 22, zoom_min: 0), source: "zones",
      ranks: paint.layerRanks)
    _ = (layer.key, layer.isHidden)
    _ = try MapSource(
      TileSchema.TileSource(
        id: "s", layers: [], tiles: [], type: .rasterDem, zoom_max: 14, zoom_min: 0))
    _ = MapSource(
      id: "r", kind: .raster(tiles: [], tileSize: 256, zoom: ZoomBounds(minZoom: 0, maxZoom: 14)),
      attribution: "OSM")
    for await state in map.subscribe() {
      _ = (state.style, state.camera, state.labelLanguage, state.sources, state.layers)
      _ = (
        state.markers, state.maxBounds, state.zoomBounds, state.activeSegments, state.waypointEdit,
        state.isAccessRequired, state.terrain, state.terrainVariant
      )
      break
    }
    map.close()
    _ = MapError(kind: .layerNotFound, name: "route").description
    return map.state
  }

  /// content draws what a map shows by id and by name, as an app does: an itinerary and a
  /// collection framed, the credential's itineraries and zones, a specification of the app's own,
  /// the catalogue's overlays and enrichments, and the layers, concepts and restricted stretches
  /// shown and hidden.
  @MainActor
  static func content(on map: MapEngine, from mountaya: Mountaya) async throws {
    let framing = CameraFit(padding: PixelPadding(24))
    if try await map.setItinerary("itn_4e5f", fit: framing) {
      map.clearItinerary()
    }
    _ = try await map.setCollection("col_6a7b", fit: framing)
    map.clearCollection()
    try await map.setItineraries(true)
    try await map.setZones(false)
    let zones = try await mountaya.tiles.getZonesSpecification()
    try map.setSpecification(zones.data, named: "zones")
    _ = map.specifications
    map.removeSpecification(named: "zones")
    map.clearSpecifications()
    map.setLayersOrganization("org_8c9d")
    let catalogue = try await map.loadLayers()
    _ = (catalogue.terrains.count, map.layersManifest?.overlays.count)
    try await map.setOverlay("snow-depth")
    map.setInstant(Date(timeIntervalSince1970: 1_773_576_000))
    _ = map.instant
    try await (map as any LayersSelectionTarget).setInstant(nil)
    map.clearOverlay()
    try await map.addEnrichment("avalanche-risk")
    _ = map.enrichments
    map.removeEnrichment("avalanche-risk")
    map.clearEnrichments()
    map.setLayerVisibility("route", visible: false)
    _ = map.isLayerVisible("route")
    for key in map.drawnLayerKeys(rank: LayerRank.zone.rank) {
      _ = map.layerIds(forKey: key)
      map.setKeyVisibility(key, visible: true)
      _ = map.isKeyVisible(key)
    }
    map.setAccessRestrictionsVisibility(false)
    _ = map.isAccessRestrictionsVisible
  }

  /// results draws Data API results and the geometry slots over a map, as an app does: each asked
  /// for or handed over, edited, removed and cleared by kind.
  @MainActor
  static func results(on map: MapEngine) async throws {
    let reach = try await map.addIsochrones(
      DataSchema.IsochronesInput(
        activity: .hikingAndTrail, locations: [[6.86, 45.83]], range: [600, 1_200],
        rangeType: .time))
    _ = (reach.id, reach.result.isochrones?.count)
    _ = try await map.editIsochrones(reach.id, patch: { $0.range = [900] })
    _ = try await map.editIsochrones(reach.id)
    map.removeAnalysis(reach.id)
    map.clearIsochrones()
    let suggested = try await map.addSuggestions(
      DataSchema.SuggestionsInput(
        activity: .hikingAndTrail, candidates: 3, distance: 10_000, start: [6.86, 45.83]),
      chosen: 1)
    _ = try await map.editSuggestions(suggested.id, chosen: 2)
    map.clearSuggestions()
    _ = try await map.addDirections(DataSchema.DirectionsResult { $0.routes = [] })
    map.clearDirections()
    _ = try await map.addPlaces(DataSchema.GeocodeResult { $0.places = [] })
    map.clearPlaces()
    let matrix = try await map.addMatrix(
      DataSchema.MatrixInput(
        activity: .hikingAndTrail, locations: [[6.86, 45.83], [6.9, 45.9]],
        metrics: [.duration]))
    _ = try await map.editMatrix(matrix.id, patch: { $0.metrics = [.distance] })
    map.clearMatrix()
    _ = try await map.setPointsOfInterest(DataSchema.PoisInput(categories: [.hut, .peak]))
    _ = try await map.editPointsOfInterest(patch: { $0.limit = 20 })
    map.clearPointsOfInterest()
    _ = MapEngine.poisAnalysisId
    map.setGeometry(
      .lineString(GeoJSONLineString(coordinates: [[6.85, 45.83], [6.87, 45.84]])), in: .preview)
    map.editGeometry(in: .preview, color: "#2b8a3e")
    map.setGeometry(.point(GeoJSONPoint(coordinates: [6.86, 45.83])), in: .highlight)
    let held: SlotGeometry = map.geometry(in: .highlight)
    _ = (held.geometry, held.color, GeometrySlot.allCases)
    map.clearGeometry(in: .preview)
  }

  /// tell reads every event a map tells, as an app's own listener does.
  static func tell(_ event: MapEvent) {
    switch event {
    case .tap(let tap), .longTap(let tap): _ = tap.marker
    case .featureTap(let position, let features), .featureHover(let position, let features):
      _ = (position, features.count)
    case .accessRefused(let status, let url): _ = (status, url)
    case .accessRestored: break
    case .failure(let url, let status, let cause): _ = (url, status, cause)
    case .layersChange(let catalogue): _ = catalogue?.terrains.count
    }
  }

  /// script drives the engine on the scripted surface, as an app's own test does with no renderer.
  @MainActor
  static func script() async throws -> [MapEvent] {
    let map = MapEngine(
      client: try Mountaya(credential: .publishable(key: "pk_test_0a1b")),
      geolocation: InertGeolocation())
    let surface = ScriptedMapSurface(drawing: map, canvas: [390, 844])
    surface.projection = ScreenProjection(point: { $0 }, position: { $0 })
    surface.liveLayers = nil
    surface.heldSources = ["trail"]
    surface.baseLabels = [ScriptedMapSurface.Label(id: "place-label", textField: "{name}")]
    surface.rendered = [
      QueriedFeature(
        id: .number(7), properties: ["segment_id": "climb"],
        geometry: .point(GeoJSONPoint(coordinates: [6.86, 45.83])), layer: "route",
        sourceLayer: nil)
    ]
    let events = map.events()
    surface.tap(at: [1, 2], position: [6.86, 45.83])
    surface.longTap(at: [1, 2], position: [6.86, 45.83])
    surface.hover(at: [1, 2], position: [6.86, 45.83])
    surface.drawFrame()
    surface.leave(at: [1, 2], position: [6.86, 45.83])
    surface.failRequest(url: "https://tiles.mountaya.com/x", status: 402, source: "trail")
    surface.failRequest(
      url: "https://tiles.mountaya.com/y", status: nil, source: "trail", superseded: false,
      cause: CancellationError())
    surface.loadTile(of: "trail")
    surface.loadStyle()
    surface.failStyle()
    _ = (surface.moves, surface.frames, surface.queries, surface.relabelled, surface.zoomLimits)
    _ = (surface.canvas, ScriptedMapSurface.Move(target: CameraTarget(), motion: .jump))
    _ = ScriptedMapSurface.Frame(bounds: [0, 0, 1, 1], fit: CameraFit())
    _ = CameraMotion.ease(duration: nil) == .fly
    _ = CameraMotion.ease() == .jump
    map.close()
    var told: [MapEvent] = []
    for await event in events {
      tell(event)
      told.append(event)
    }
    let fix: GeolocationFix = await Here().locate()
    if case .refused(let reason) = fix {
      _ = GeolocationRefusal.allCases.contains(reason)
    }
    _ = GeolocationPermission.allCases
    _ = await InertGeolocation().permission()
    return told
  }

  /// controls drives a layers selection and a locate control over the map itself, which reports
  /// the terrain it shows and reads its standing permission without asking.
  @MainActor
  static func controls(on map: MapEngine) async {
    _ = (map.terrain, await map.isLocationRefused())
    let selection = LayersSelectionEngine(map: map)
    selection.setOverlay("snow-depth")
    let control = GeolocateControlEngine(map: map)
    control.locate()
    let targets: (any LayersSelectionTarget, any GeolocateControlTarget) = (map, map)
    _ = targets
    selection.close()
    control.close()
  }

  #if os(iOS) && !targetEnvironment(macCatalyst)
    /// TrailMap is the README's map, compiled for iOS with the Elements trait: the view over the
    /// engine, its ready callback reaching MapLibre's own map.
    struct TrailMap: View {
      @State private var map: MapEngine

      init(mountaya: Mountaya) {
        _map = State(initialValue: MapEngine(client: mountaya))
      }

      var body: some View {
        MapView(map, onReady: { (mapView: MLNMapView) in mapView.showsScale = true })
          .ignoresSafeArea()
          .task { try? await map.setTerrain() }
      }
    }

    /// ZoomButton is a control of an app's own, drawing a glyph of the bundled control set in the
    /// tint, and one of the marker set named to assistive technologies.
    struct ZoomButton: View {
      var body: some View {
        Button {
        } label: {
          Label {
            Text("Zoom in")
          } icon: {
            Glyph("zoom-in")
          }
        }
        Glyph("hut", in: .marker, size: 24, color: .accentColor, label: "Refuge")
      }
    }

    /// PickedHut is the README's tapped map, compiled for iOS with the Elements trait: a marker,
    /// the hut a tap picks, and the camera where it rests.
    struct PickedHut: View {
      @State private var map: MapEngine
      @State private var picked: String?
      @State private var camera: CameraPose?

      init(mountaya: Mountaya) {
        _map = State(initialValue: MapEngine(client: mountaya))
      }

      var body: some View {
        MapView(
          map, readout: false, onTap: { tap in picked = tap.marker },
          onCameraChange: { camera = $0 }
        )
        .task {
          try? map.addMarker(
            MapMarker(id: "hut", position: [6.8652, 45.9237], glyph: "hut", label: "Refuge"))
          try? map.setZoomBounds(min: 8, max: 17)
        }
      }
    }

    /// TrailControls is the README's control stack, compiled for iOS with the Elements trait: the
    /// stack over the map, the app's own controls among it, the panel open and the preferences
    /// held by the app, its words, its tokens and a panel of the app's own.
    struct TrailControls: View {
      @State private var map: MapEngine
      @State private var open: MapPanel?
      @State private var units = UnitPreferences(language: "fr")
      @State private var exporting = false

      init(mountaya: Mountaya) {
        _map = State(initialValue: MapEngine(client: mountaya))
      }

      var body: some View {
        var tokens = ElementTokens.standard
        tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
        return MapView(map)
          .overlay {
            MapControls(
              map, zoom: true, compass: true, geolocate: true, layers: true, pois: true,
              preferences: true, corner: .topRight, openPanel: $open, unitPreferences: $units,
              offersTime: true, thumbnail: { _, slug in Image("layers/\(slug)") },
              strings: ["controls.layers": "Fonds"]
            ) {
              DownloadControl { exporting = true }
              DirectionsControl(strings: ["controls.directions": "Itinéraire"]) {
                exporting = false
              }
              PanelControl("filters", label: "Filters", glyph: "controls", help: "Huts only") {
                Text("Huts only")
              }
              PanelControl(.layers, label: "Layers", glyph: "layers", content: { EmptyView() })
            }
          }
          .mountayaTokens(tokens)
          .mountayaScope(ElementsScopeStatement(language: .fr, locale: "fr-CH"))
      }
    }

    /// StoppedClock is a clock of the app's own, which a replay stops at one instant, and the time
    /// of the layers panel reads.
    struct StoppedClock: WallClock {
      var now: Date { Date(timeIntervalSince1970: 1_773_480_413.9) }
    }

    /// OwnStack is a stack composed of the controls one by one, each with a handler of the app's
    /// own in place of its default, and the three panels drawn where the app places them.
    struct OwnStack: View {
      let map: MapEngine
      @State private var selection = LayersSelectionEngine()
      @State private var units = UnitPreferences(language: "en")
      @Environment(\.mountayaScope) private var scope
      @Environment(\.mountayaTokens) private var tokens

      var body: some View {
        VStack {
          ZoomControl(
            map: map, strings: ["controls.zoomIn": "Plus"], onZoomInTap: {}, onZoomOutTap: {})
          CompassControl(map: nil, strings: ["controls.compass": "Nord"], onTap: {})
          GeolocateControl(
            map: map, isLocating: false, strings: ["controls.geolocate": "Ici"], onTap: {},
            onError: { _ in })
          DownloadControl(strings: ["controls.download": "Fichier"]) {}
          LayersPanel(
            selection: selection, isLocked: { $0 == "snow-depth" }, offersTime: true,
            thumbnail: { choice, slug in choice == .terrain ? Image(slug) : nil },
            strings: ["layers.locked": "Fermé", "layers.timeHoursAhead": "+{count} h"],
            onLockedTap: { _ in }
          )
          .environment(\.mountayaClock, StoppedClock())
          POIPanel(
            map: map, keys: ["parking"],
            groups: [POIPanelGroup(id: "water", label: "Water", keys: ["spring"])],
            activeGroups: ["water"], labels: ["parking": "Parking"], minZoom: 12,
            showsAllToggle: true, strings: ["pois.displayOnMap": "Tout"], onToggle: { _, _ in },
            onToggleGroup: { _, _ in }, onToggleAll: { _ in })
          PreferencesPanel(preferences: $units, map: map, strings: ["preferences.metric": "Mètres"])
          MapControls(nil, corner: MapCorner.bottomLeft, strings: nil)
          Glyph("zoom-in", color: nil)
        }
        .disabled(scope.language != .en || tokens.accent.dark != nil)
        .task { selection.configure(map: map) }
        .environment(\.mountayaScope, ElementsScope.standard)
        .environment(\.mountayaTokens, ElementTokens.standard)
        .onAppear { _ = (MapPanel.layers, MapPanel.pois, MapPanel.preferences, MapCorner.allCases) }
      }
    }
  #endif
}
