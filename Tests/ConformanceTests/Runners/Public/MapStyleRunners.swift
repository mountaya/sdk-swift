import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapStyleAttribution answers what a map credits, through the engine's `credits`: each of the
  /// case's sources added to the map with the credit it states, null and absent alike none, and
  /// drawn where the case says a layer draws it, by a layer of the map's own drawing from it at
  /// every zoom. A source the case names by its `tileJson` is the base map's, which the scripted
  /// surface reports as `MapView`'s renderer reads MapLibre Native's, its credit the style's own or,
  /// where it states none, its TileJSON's. Mountaya's credit is held to the one a map drawing
  /// nothing credits, and the credits are answered as a set, the order a renderer lists them in
  /// being its own.
  static let mapStyleAttribution = Runner(id: "map.style.attribution", table: .public) {
    fixture, fixtureCase in
    let sources = try fixtureCase.input.array(at: "sources")
    let (credits, alone) = try await MainActor.run { () throws -> ([String], [String]) in
      let bare = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      for source in sources {
        let id = try source.string(at: "id")
        if let tileJson = source["tileJson"] {
          surface.baseSources.append(
            ScriptedMapSurface.BaseSource(
              attribution: try source.optionalString(at: "attribution")
                ?? tileJson.optionalString(at: "attribution"),
              isDrawn: try source.flag(at: "drawn")))
          continue
        }
        map.addSource(
          MapSource(
            id: id, kind: .geoJson(GeoJSONFeatureCollection(features: [])),
            attribution: try source.optionalString(at: "attribution")))
        if try source.flag(at: "drawn") {
          map.addLayer(
            MapLayer(
              id: "\(id)-drawn", type: .line, source: id,
              rank: LayerRank.overlay.rank))
        }
      }
      return (map.credits, bare.credits)
    }
    guard alone.count == 1, let mountaya = alone.first else {
      throw FixtureError(description: "a map drawing nothing credits \(alone)")
    }
    try fixture.holdConstants([:], values: ["mountayaCredit": .string(mountaya)])
    return .members(credits.map { .string($0) })
  }

  /// mapStyleLabelScope answers which labels a map's label language relabels, through the engine's
  /// `setLabelLanguage(_:)` on the scripted surface, which draws the case's `base` labels and
  /// records each label the engine rewrites: the map's own labels placed as symbol layers of a
  /// specification's source, then the language set; where the case switches base map, the
  /// surface's labels become the ones the switch brings in, a style loads, and what it rewrites then
  /// is the answer after the switch.
  static let mapStyleLabelScope = Runner(id: "map.style.label-scope", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let language = RestSchema.Language(rawValue: try input.string(at: "language"))
    func labels(_ key: String) throws(FixtureError) -> [ScriptedMapSurface.Label]? {
      guard input[key] != nil else { return nil }
      var read: [ScriptedMapSurface.Label] = []
      for layer in try input.array(at: key) {
        read.append(
          ScriptedMapSurface.Label(
            id: try layer.string(at: "id"), textField: .string(try layer.string(at: "textField"))))
      }
      return read
    }
    let base = try labels("base") ?? []
    let placed = try labels("placed") ?? []
    let switchTo = try labels("switchTo")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(
        client: try MapFixtures.client(), labelLanguage: .en,
        geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      surface.baseLabels = base
      for label in placed {
        map.addLayer(
          MapLayer(
            id: label.id, type: .symbol, source: "placed",
            sourceLayer: "itinerary_points", rank: LayerRank.itineraryPoint.rank,
            layout: ["text-field": label.textField]))
      }
      map.setLabelLanguage(language)
      let relabelled = surface.relabelled
      var afterSwitch: OrderedJSON = .null
      if let switchTo {
        surface.baseLabels = switchTo
        surface.loadStyle()
        afterSwitch = GeoFixtures.texts(Array(surface.relabelled.dropFirst(relabelled.count)))
      }
      return .value(
        .object([
          OrderedJSON.Member(key: "afterSwitch", value: afterSwitch),
          OrderedJSON.Member(key: "relabelled", value: GeoFixtures.texts(relabelled)),
        ]))
    }
  }

  /// mapEngineClosed answers what a closed map does, through the engine on the scripted surface:
  /// before it closes it draws an itinerary's line under the point `[1, 2]`, holds its zoom window
  /// to 8 to 12, labels in French, hears a refusal of access to the itinerary's source and listens
  /// to its events; then the case's call is made on the closed map, or its gesture played on the
  /// surface. Swift's names for the calls are the engine's: `jump(to:)` for `jumpTo`, `zoomIn()`,
  /// `setZoomBounds(min:max:)` for `setConstraints`, `setItinerary(_:fit:)`,
  /// `features(at:)`, `project(_:)`, `unproject(_:)`, the state's zoom bounds,
  /// label language and standing refusal for the three getters, `elevation(at:)` and `close()`.
  /// `changed` is a camera move or a fit the surface was handed, or a state the engine reported;
  /// `read` a request its client sent; `told` an event a stream taken after the close is told.
  static let mapEngineClosed = Runner(id: "map.engine.closed", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let call = try input.optionalString(at: "call")
    let gesture = try input.optionalString(at: "renderer")
    let args = input["args"]?.elements ?? []
    let exchange = MapFixtures.Recording(
      answer: .data(
        operation: "terrainSamples",
        result: .object([
          OrderedJSON.Member(
            key: "samples",
            value: .array([.object([OrderedJSON.Member(key: "elevation", value: .number(1834))])]))
        ])))
    let (map, surface, before) = try await MainActor.run {
      () throws -> (MapEngine, ScriptedMapSurface, MapFixtures.Closed) in
      let map = MapEngine(
        client: try MapFixtures.client(exchange: exchange), geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      map.addSource(
        MapSource(id: "itinerary", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
      map.addLayer(
        MapLayer(
          id: "itinerary-line", type: .line, source: "itinerary",
          rank: LayerRank.itineraryLine.rank))
      surface.rendered = [
        QueriedFeature(
          properties: [:], geometry: .point(GeoJSONPoint(coordinates: [6.86, 45.83])),
          layer: "itinerary-line")
      ]
      try map.setZoomBounds(min: 8, max: 12)
      map.setLabelLanguage(.fr)
      surface.failRequest(url: "https://tiles.test/x", status: 402, source: "itinerary")
      let listening = map.events()
      map.close()
      return (map, surface, MapFixtures.Closed(map: map, surface: surface, listening: listening))
    }
    let sentBefore = await exchange.sent.count
    var answer: OrderedJSON = .null
    if let gesture {
      guard gesture == "click" else {
        throw FixtureError(description: "no gesture is called `\(gesture)`")
      }
      await MainActor.run { surface.tap(at: [1, 2], position: [6.86, 45.83]) }
    } else if let call {
      answer = try await MapFixtures.call(call, args: args, on: map)
    } else {
      throw FixtureError(description: "the input states neither a call nor a gesture")
    }
    let read = await exchange.sent.count > sentBefore
    let (changed, told) = try await before.afterwards()
    return .value(
      .object([
        OrderedJSON.Member(key: "answer", value: answer),
        OrderedJSON.Member(key: "changed", value: .bool(changed)),
        OrderedJSON.Member(key: "read", value: .bool(read)),
        OrderedJSON.Member(key: "told", value: .array(told.map { .string("\($0)") })),
      ]))
  }
}

extension MapFixtures {
  /// Closed is a map as it closed: the state it ended on, what its surface had been handed, and a
  /// stream of its events taken before the close.
  @MainActor
  struct Closed {
    let map: MapEngine
    let surface: ScriptedMapSurface
    let listening: AsyncStream<MapEvent>
    let state: MapState
    let moves: Int
    let frames: Int

    init(map: MapEngine, surface: ScriptedMapSurface, listening: AsyncStream<MapEvent>) {
      self.map = map
      self.surface = surface
      self.listening = listening
      self.state = map.state
      self.moves = surface.moves.count
      self.frames = surface.frames.count
    }

    /// afterwards answers whether the renderer was asked to change anything since the close, and
    /// every event a stream taken after it is told, the one taken before having ended there.
    func afterwards() async throws -> (changed: Bool, told: [MapEvent]) {
      let changed =
        map.state != state || surface.moves.count != moves || surface.frames.count != frames
      var told: [MapEvent] = []
      for await event in map.events() {
        told.append(event)
      }
      // The stream taken before the close holds only what was told before it, and has ended.
      for await _ in listening {}
      return (changed, told)
    }
  }

  /// call makes the closed map's call the case names, with its arguments, and answers what it
  /// answers as the fixtures write it.
  @MainActor
  static func call(_ call: String, args: [OrderedJSON], on map: MapEngine) async throws
    -> OrderedJSON
  {
    func position() throws(FixtureError) -> [Double] {
      guard let first = args.first else {
        throw FixtureError(description: "`\(call)` is given no argument")
      }
      return try first.numberList(naming: call)
    }
    switch call {
    case "jumpTo":
      let zoom = try args.first?.number(at: "zoom")
      try map.jump(to: CameraTarget(zoom: zoom))
      return .null
    case "zoomIn":
      map.zoomIn()
      return .null
    case "setConstraints":
      guard let window = args.first?["zoom"] else {
        throw FixtureError(description: "`setConstraints` states no zoom window")
      }
      try map.setZoomBounds(
        min: .zoom(try window.number(at: "min")), max: .zoom(try window.number(at: "max")))
      return .null
    case "setItinerary":
      guard let id = args.first?.stringValue else {
        throw FixtureError(description: "`setItinerary` is given no id")
      }
      let drawn = try await map.setItinerary(id)
      return .object([OrderedJSON.Member(key: "drawn", value: .bool(drawn))])
    case "featuresAt":
      return .array(try map.features(at: try position()).map(MapFixtures.answer))
    case "project":
      return GeoFixtures.numbers(map.project(try position()))
    case "unproject":
      return GeoFixtures.numbers(map.unproject(try position()))
    case "getZoomLimits":
      return GeoCameraFixtures.windowAnswer(map.state.zoomBounds)
    case "getLanguage":
      return .string(map.state.labelLanguage.rawValue)
    case "isAccessRequired":
      return .bool(map.state.isAccessRequired)
    case "elevationAt":
      return try await map.elevation(at: try position()).map { .number($0) } ?? .null
    case "destroy":
      map.close()
      return .null
    default:
      throw FixtureError(description: "no call is called `\(call)`")
    }
  }
}
