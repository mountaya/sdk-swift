import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapSpecificationStyle answers what a map draws of a tile specification, through
  /// `setSpecification(_:named:)`: each layer the case hid hidden first, by its id, then the
  /// specification drawn, and the state's sources and layers written as MapLibre's style
  /// specification writes them. The restricted-stretch pair the map draws beside an itinerary line
  /// of its own is no layer of the specification, and is left out (`map.road-access.layers` reads
  /// it). A refused specification draws nothing, which the runner holds to.
  static let mapSpecificationStyle = Runner(id: "map.specification.style", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let specification = try GeoFixtures.decoded(
      TileSchema.TileSpecification.self, from: input["specification"] ?? .null)
    let hidden = try GeoFixtures.textList(input, at: "hidden")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      for id in hidden {
        map.setLayerVisibility(id, visible: false)
      }
      do throws(MapError) {
        try map.setSpecification(specification, named: "specification")
      } catch {
        guard map.state.layers.isEmpty, map.state.sources.isEmpty else {
          throw FixtureError(description: "a refused specification drew \(map.state.layers)")
        }
        return .value(
          .object([
            OrderedJSON.Member(key: "layers", value: .array([])),
            OrderedJSON.Member(key: "refused", value: .string(MapFixtures.kind(error))),
            OrderedJSON.Member(key: "sources", value: .object([])),
          ]))
      }
      let listed = specification.sources.flatMap { $0.layers.map(\.id) }
      let layers = map.state.layers.filter { layer in listed.contains(layer.id) }
      return .value(
        .object([
          OrderedJSON.Member(key: "layers", value: .array(layers.map(MapFixtures.styleLayer))),
          OrderedJSON.Member(key: "refused", value: .null),
          OrderedJSON.Member(
            key: "sources",
            value: .object(
              map.state.sources.map {
                OrderedJSON.Member(key: $0.id, value: MapFixtures.styleSource($0))
              })),
        ]))
    }
  }

  /// mapLayersRankInsertion answers the order a renderer draws once every step is played, through
  /// `addLayer(_:)` and `removeLayer(_:)`: the base map's own layers, which carry no rank and
  /// which `MapView`'s renderer keeps beneath every layer the map places, then the layers the
  /// engine holds, bottom first.
  static let mapLayersRankInsertion = Runner(id: "map.layers.rank-insertion", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let base = try GeoFixtures.textList(input, at: "base")
    let steps = try input.array(at: "steps")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      for step in steps {
        let id = try step.string(at: "id")
        switch try step.string(at: "step") {
        case "place":
          map.addLayer(
            MapLayer(
              id: id, type: .line, source: "placed",
              rank: try step.integer(at: "rank")))
        case "remove":
          map.removeLayer(id)
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
      }
      return .value(GeoFixtures.texts(base + map.state.layers.map(\.id)))
    }
  }

  /// mapLayersKeys answers which concepts a map draws, through `setSpecification(_:named:)`, each
  /// content a specification of one vector source holding its layers, drawn under its content's
  /// name, then `setLayerVisibility(_:visible:)` for each layer hidden, and the engine's
  /// `drawnLayerKeys(rank:)`, `layerIds(forKey:)` and `isKeyVisible(_:)`.
  static let mapLayersKeys = Runner(id: "map.layers.keys", table: .public) { _, fixtureCase in
    let input = fixtureCase.input
    let drawn = try input.array(at: "drawn")
    let hidden = try GeoFixtures.textList(input, at: "hidden")
    let band = try input.integer(at: "band")
    let key = try input.string(at: "key")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      for entry in drawn {
        let content = try entry.string(at: "content")
        try map.setSpecification(
          try MapFixtures.specification(content, layers: try entry.array(at: "layers")),
          named: content)
      }
      for id in hidden {
        map.setLayerVisibility(id, visible: false)
      }
      return .value(
        .object([
          OrderedJSON.Member(key: "keys", value: GeoFixtures.texts(map.drawnLayerKeys())),
          OrderedJSON.Member(
            key: "keysInBand", value: GeoFixtures.texts(map.drawnLayerKeys(rank: band))),
          OrderedJSON.Member(key: "layerIds", value: GeoFixtures.texts(map.layerIds(forKey: key))),
          OrderedJSON.Member(key: "shown", value: .bool(map.isKeyVisible(key))),
        ]))
    }
  }

  /// mapLayersVisibility answers a layer's visibility after each step, through the engine on the
  /// scripted surface: `draw` is `setSpecification(_:named:)` of one vector source whose layers are
  /// symbols of `poi_food`, `clear` is `removeSpecification(named:)`, `hide` and `show` are
  /// `setLayerVisibility(_:visible:)`, and `switch` is `setStyle(_:)` to a document of its own,
  /// which the surface then loads. `shown` is `isLayerVisible(_:)`; `drawn` is how the state the
  /// renderer draws holds the layer, `none` or `visible`, or null where it holds none.
  static let mapLayersVisibility = Runner(id: "map.layers.visibility", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let watched = try GeoFixtures.textList(input, at: "watched")
    let steps = try input.array(at: "steps")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      var switches = 0
      var answers: [OrderedJSON] = []
      for step in steps {
        switch try step.string(at: "step") {
        case "draw":
          let content = try step.string(at: "content")
          let layers = try GeoFixtures.textList(step, at: "layers").map { id in
            OrderedJSON.object([
              OrderedJSON.Member(key: "id", value: .string(id)),
              OrderedJSON.Member(key: "source_layer", value: .string("poi_food")),
              OrderedJSON.Member(key: "type", value: .string("symbol")),
            ])
          }
          try map.setSpecification(
            try MapFixtures.specification(content, layers: layers), named: content)
        case "clear":
          map.removeSpecification(named: try step.string(at: "content"))
        case "hide":
          map.setLayerVisibility(try step.string(at: "layer"), visible: false)
        case "show":
          map.setLayerVisibility(try step.string(at: "layer"), visible: true)
        case "switch":
          switches += 1
          map.setStyle(URL(string: "https://tiles.test/base-\(switches).json"))
          surface.loadStyle()
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
        answers.append(
          .object(
            watched.map { id in
              let layer = map.state.layers.first { $0.id == id }
              return OrderedJSON.Member(
                key: id,
                value: .object([
                  OrderedJSON.Member(
                    key: "drawn",
                    value: layer.map { .string($0.isHidden ? "none" : "visible") } ?? .null),
                  OrderedJSON.Member(key: "shown", value: .bool(map.isLayerVisible(id))),
                ]))
            }))
      }
      return .value(.array(answers))
    }
  }

  /// mapLayersManifest answers how a map reads the layers catalogue, played over an exchange that
  /// holds every read until a step settles it: `load` is a call of `loadLayers()` nobody waits on,
  /// answered `closed` where it throws a `MapError` of kind `closed`, `answer` a catalogue whose
  /// elevation names the read, `fail` a 404, `close` `close()`, and `scope`
  /// `setLayersOrganization(_:)`. Every call runs in a task preferring the main queue, and each
  /// step settles before the next. `held` is `layersManifest`, and `told` each `layersChange` the
  /// map told, as the read whose catalogue it carries.
  static let mapLayersManifest = Runner(id: "map.layers.manifest", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await MapContentScripts.manifest(try fixtureCase.input.array(at: "steps"))
  }

  /// mapOverlaysComposition answers which overlays a map draws after each step, over a catalogue of
  /// the case's classic and enrichment overlays, each drawing one fill layer named after its slug:
  /// `overlay` is `setOverlay(_:)`, or `clearOverlay()` for null, `add` is `addEnrichment(_:)`, and
  /// `remove` is `removeEnrichment(_:)`. `overlay` is the classic overlay whose layer the state
  /// holds, and `enrichments` the engine's `enrichments`.
  static let mapOverlaysComposition = Runner(id: "map.overlays.composition", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let overlays = input["overlays"] ?? .null
    let classic = try GeoFixtures.textList(overlays, at: "classic")
    let enrichment = try GeoFixtures.textList(overlays, at: "enrichment")
    let steps = try input.array(at: "steps")
    let body = MapFixtures.catalogueBody(classic: classic, enrichment: enrichment)
    return try await MapContentScripts.overlays(
      steps, classic: classic, exchange: MapFixtures.Serving { _ in (200, body) })
  }

  /// mapOverlaysInstant answers what a map draws after each step for the instant pinned, over the
  /// case's manifest served at its `tilesBaseUrl`: each overlay one vector source,
  /// `<slug>-source`, of one fill layer at every zoom, `<slug>-layer`, its addresses and its
  /// `capabilities` as the case writes them, the classic ones in one classic category and the
  /// enrichments in the one keyed `enrichment`. `overlay` is `setOverlay(_:)`, or `clearOverlay()`
  /// for null, `add` is `addEnrichment(_:)`, `instant` is `setInstant(_:)`, `switch` is
  /// `setStyle(_:)` to a document of its own, which the scripted surface then loads, as
  /// `map.basemap.replay` plays a switch, and `fail` the renderer's failure of the tile 3/4/5 of
  /// the first address the map draws the source of the overlay `source` from, under the credential
  /// the client sends, as `map.events.access-refused` reads one. Each step answers the instant the
  /// map holds, the classic overlay whose layer the state holds, the enrichments, the addresses
  /// the state hands the renderer for each overlay drawn, and, for a `fail`, what was told.
  static let mapOverlaysInstant = Runner(id: "map.overlays.instant", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let overlays = try input.array(at: "overlays")
    let tilesBaseUrl = try input.string(at: "tilesBaseUrl")
    guard let tiles = URL(string: tilesBaseUrl) else {
      throw FixtureError(description: "`\(tilesBaseUrl)` is no address")
    }
    var classic: [String] = []
    var enrichment: [TileSchema.Overlay] = []
    var classicOverlays: [TileSchema.Overlay] = []
    for written in overlays {
      let overlay = try MapFixtures.stampedOverlay(written)
      switch try written.string(at: "kind") {
      case "classic":
        classic.append(overlay.slug)
        classicOverlays.append(overlay)
      case "enrichment": enrichment.append(overlay)
      case let other: throw FixtureError(description: "`\(other)` is no kind of overlay")
      }
    }
    let catalogue = GeoTileFixtures.layers([
      GeoTileFixtures.category("conditions", children: classicOverlays),
      GeoTileFixtures.category(enrichmentCategorySlug, children: enrichment),
    ])
    let body = Data(#"{"data": "#.utf8) + (try JSONEncoder().encode(catalogue)) + Data("}".utf8)
    return try await MapContentScripts.instants(
      try input.array(at: "steps"), classic: classic, tiles: tiles,
      exchange: MapFixtures.Serving { _ in (200, body) })
  }

  /// mapBasemapTerrain answers which base map a map shows after each step, over a catalogue of the
  /// case's terrains: `terrain` is `setTerrain(_:)` and `variant` `setTerrainVariant(_:)`. `style`
  /// is the document the state asks its renderer for, `terrain` and `variant` the state's own.
  static let mapBasemapTerrain = Runner(id: "map.basemap.terrain", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let terrains = try input.array(at: "terrains").map { terrain throws(FixtureError) in
      MapFixtures.terrain(
        slug: try terrain.string(at: "slug"), light: try terrain.string(at: "light"),
        dark: try terrain.string(at: "dark"))
    }
    let body = MapFixtures.catalogueBody(terrains: terrains)
    return try await MapContentScripts.terrain(
      try input.array(at: "steps"), exchange: MapFixtures.Serving { _ in (200, body) })
  }

  /// mapSlotsLatestRequest answers which request each slot draws, played over an exchange that
  /// holds every read until a step answers it: `request` is `setItinerary(_:fit:)` or
  /// `setCollection(_:fit:)`, `toggle` `setItineraries(_:)` or `setZones(_:)`, `clear` the slot's
  /// clear, `answer` a specification of one source drawing the line `line-` then the read's name,
  /// and `withdraw` the cancellation of the task that asked, which is how a Swift caller withdraws
  /// a call. Every call runs in a task preferring the main queue, and each step settles before the
  /// next. A read is named by its path: the id it asks for, or the content a toggle reads.
  static let mapSlotsLatestRequest = Runner(id: "map.slots.latest-request", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await MapContentScripts.slots(try fixtureCase.input.array(at: "steps"))
  }
}

/// MapContentScripts plays the content scripts of the map's fixtures on the main actor, where the
/// engine and every read it sends run.
@MainActor
enum MapContentScripts {
  /// Outcomes is what each call of a script came to, in the order the calls were made.
  @MainActor
  final class Outcomes {
    var values: [OrderedJSON] = []
  }

  /// manifest plays `map.layers.manifest`'s steps.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func manifest(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let held = MapFixtures.Held()
    let map = MapEngine(
      client: try MapFixtures.client(exchange: held), geolocation: InertGeolocation())
    let told = map.events()
    let loads = Outcomes()
    func readOf(_ catalogue: TileSchema.Layers?) -> OrderedJSON {
      guard let mark = catalogue?.elevation.id, mark.hasPrefix("read-"),
        let read = Int(mark.dropFirst(5))
      else { return .null }
      return .number(Double(read))
    }
    /// progress is what the script reads to know a step has come to rest: each load's outcome, the
    /// catalogue the map holds, and the reads sent, held and withdrawn.
    func progress() -> [OrderedJSON] {
      [.array(loads.values), readOf(map.layersManifest)]
        + held.progress.map { .number(Double($0)) }
    }
    for step in steps {
      switch try step.string(at: "step") {
      case "load":
        let index = loads.values.count
        loads.values.append(.null)
        _ = MainQueue.run {
          do {
            loads.values[index] = readOf(try await map.loadLayers())
          } catch let refusal as MapError where refusal.kind == .closed {
            loads.values[index] = .string("closed")
          } catch {
            loads.values[index] = .string("failed")
          }
        }
      case "answer":
        let read = try step.integer(at: "read")
        try held.answer(read, body: MapFixtures.catalogueBody(mark: "read-\(read)"))
      case "fail":
        try held.fail(try step.integer(at: "read"))
      case "scope":
        map.setLayersOrganization(try step.optionalString(at: "organization"))
      case "close":
        map.close()
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      await MainQueue.settle { progress() }
    }
    let reads = held.reads.map { read -> OrderedJSON in
      let items = URLComponents(url: read.request.url, resolvingAgainstBaseURL: false)?.queryItems
      return .object(
        (items ?? []).map { OrderedJSON.Member(key: $0.name, value: .string($0.value ?? "")) })
    }
    let holding = readOf(map.layersManifest)
    // A load still waiting as the script ends holds nothing, before the reads still out are let go.
    let outcomes = loads.values
    held.release()
    await MainQueue.settle { progress() }
    map.close()
    var changes: [OrderedJSON] = []
    for await event in told {
      if case .layersChange(let catalogue) = event {
        changes.append(readOf(catalogue))
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "held", value: holding),
        OrderedJSON.Member(key: "loads", value: .array(outcomes)),
        OrderedJSON.Member(key: "reads", value: .array(reads)),
        OrderedJSON.Member(key: "told", value: .array(changes)),
      ]))
  }

  /// overlays plays `map.overlays.composition`'s steps, each call awaited, since the catalogue
  /// answers at once.
  static func overlays(
    _ steps: [OrderedJSON], classic: [String], exchange: MapFixtures.Serving
  ) async throws -> RunnerOutcome {
    let map = MapEngine(
      client: try MapFixtures.client(exchange: exchange), geolocation: InertGeolocation())
    var answers: [OrderedJSON] = []
    for step in steps {
      var refused: OrderedJSON = .null
      do {
        switch try step.string(at: "step") {
        case "overlay":
          if let slug = try step.optionalString(at: "slug") {
            try await map.setOverlay(slug)
          } else {
            map.clearOverlay()
          }
        case "add":
          try await map.addEnrichment(try step.string(at: "slug"))
        case "remove":
          map.removeEnrichment(try step.string(at: "slug"))
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
      } catch let error as MapError {
        refused = .string(MapFixtures.kind(error))
      }
      let drawn = classic.filter { slug in map.state.layers.contains { $0.id == "\(slug)-layer" } }
      guard drawn.count <= 1 else {
        throw FixtureError(description: "two classic overlays are drawn: \(drawn)")
      }
      answers.append(
        .object([
          OrderedJSON.Member(key: "enrichments", value: GeoFixtures.texts(map.enrichments)),
          OrderedJSON.Member(key: "overlay", value: drawn.first.map { .string($0) } ?? .null),
          OrderedJSON.Member(key: "refused", value: refused),
        ]))
    }
    return .value(.array(answers))
  }

  /// instants plays `map.overlays.instant`'s steps, each call awaited, since the catalogue answers
  /// at once. A tap on the canvas after each step marks where it ends among the events told, which
  /// are read once the map is closed.
  static func instants(
    _ steps: [OrderedJSON], classic: [String], tiles: URL, exchange: MapFixtures.Serving
  ) async throws -> RunnerOutcome {
    let map = MapEngine(
      client: try MapFixtures.client(baseUrls: BaseURLs(tiles: tiles), exchange: exchange),
      style: URL(string: "https://tiles.test/base-0.json"), geolocation: InertGeolocation())
    let surface = ScriptedMapSurface(drawing: map)
    surface.loadStyle()
    let events = map.events()
    var switches = 0
    var answers: [OrderedJSON] = []
    var fails: [Bool] = []
    for step in steps {
      let name = try step.string(at: "step")
      switch name {
      case "overlay":
        if let slug = try step.optionalString(at: "slug") {
          try await map.setOverlay(slug)
        } else {
          map.clearOverlay()
        }
      case "add":
        try await map.addEnrichment(try step.string(at: "slug"))
      case "instant":
        map.setInstant(try step.optionalString(at: "at").map(GeoTimeFixtures.instant))
      case "switch":
        switches += 1
        map.setStyle(URL(string: "https://tiles.test/base-\(switches).json"))
        surface.loadStyle()
      case "fail":
        let source = "\(try step.string(at: "source"))-source"
        guard let first = Self.tiles(of: source, on: map).first else {
          throw FixtureError(description: "the map draws no address of `\(source)`")
        }
        let address = first.replacingOccurrences(of: "{z}", with: "3")
          .replacingOccurrences(of: "{x}", with: "4").replacingOccurrences(of: "{y}", with: "5")
        surface.failRequest(url: address, status: try step.integer(at: "status"), source: source)
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      surface.tap(at: [0, 0], position: [0, 0])
      fails.append(name == "fail")
      let drawn = classic.filter { slug in map.state.layers.contains { $0.id == "\(slug)-layer" } }
      guard drawn.count <= 1 else {
        throw FixtureError(description: "two classic overlays are drawn: \(drawn)")
      }
      answers.append(
        .object([
          OrderedJSON.Member(key: "enrichments", value: GeoFixtures.texts(map.enrichments)),
          OrderedJSON.Member(key: "instant", value: GeoControlFixtures.millisecondsOf(map.instant)),
          OrderedJSON.Member(key: "overlay", value: drawn.first.map { .string($0) } ?? .null),
          OrderedJSON.Member(
            key: "tiles",
            value: .object(
              (drawn + map.enrichments).map { slug in
                OrderedJSON.Member(
                  key: slug, value: GeoFixtures.texts(Self.tiles(of: "\(slug)-source", on: map)))
              })),
        ]))
    }
    map.close()
    // The events of each step, up to the tap that marks its end.
    var told: [[MapEvent]] = [[]]
    for await event in events {
      if case .tap = event {
        told.append([])
      } else {
        told[told.count - 1].append(event)
      }
    }
    return .value(
      .array(
        answers.enumerated().map { index, answer in
          guard case .object(let members) = answer else { return answer }
          var heard: OrderedJSON = .null
          if fails[index] {
            var refused: OrderedJSON = .null
            var error = false
            for event in told.indices.contains(index) ? told[index] : [] {
              switch event {
              case .accessRefused(let status, let url):
                refused = .object([
                  OrderedJSON.Member(key: "status", value: .number(Double(status))),
                  OrderedJSON.Member(key: "url", value: .string(url)),
                ])
              case .failure: error = true
              default: continue
              }
            }
            heard = .object([
              OrderedJSON.Member(key: "accessRefused", value: refused),
              OrderedJSON.Member(key: "error", value: .bool(error)),
            ])
          }
          return .object(members + [OrderedJSON.Member(key: "told", value: heard)])
        }))
  }

  /// tiles is the addresses the state of `map` hands its renderer for the source `id`, none where it
  /// holds no tile source of that id.
  static func tiles(of id: String, on map: MapEngine) -> [String] {
    switch map.state.sources.first(where: { $0.id == id })?.kind {
    case .vector(let tiles, _)?, .raster(let tiles, _, _)?, .rasterDem(let tiles, _, _)?: tiles
    default: []
    }
  }

  /// terrain plays `map.basemap.terrain`'s steps, each call awaited, since the catalogue answers at
  /// once.
  static func terrain(_ steps: [OrderedJSON], exchange: MapFixtures.Serving) async throws
    -> RunnerOutcome
  {
    let map = MapEngine(
      client: try MapFixtures.client(exchange: exchange), geolocation: InertGeolocation())
    var answers: [OrderedJSON] = []
    for step in steps {
      var refused: OrderedJSON = .null
      do {
        switch try step.string(at: "step") {
        case "terrain":
          try await map.setTerrain(try step.optionalString(at: "slug"))
        case "variant":
          try await map.setTerrainVariant(
            TileSchema.TerrainVariant(rawValue: try step.string(at: "variant")))
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
      } catch let error as MapError {
        refused = .string(MapFixtures.kind(error))
      }
      answers.append(
        .object([
          OrderedJSON.Member(key: "refused", value: refused),
          OrderedJSON.Member(
            key: "style", value: map.state.style.map { .string($0.absoluteString) } ?? .null),
          OrderedJSON.Member(key: "terrain", value: map.state.terrain.map { .string($0) } ?? .null),
          OrderedJSON.Member(key: "variant", value: .string(map.state.terrainVariant.rawValue)),
        ]))
    }
    return .value(.array(answers))
  }

  /// slots plays `map.slots.latest-request`'s steps.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func slots(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let held = MapFixtures.Held()
    let map = MapEngine(
      client: try MapFixtures.client(exchange: held), geolocation: InertGeolocation())
    var calls: [String: Task<Void, any Error>] = [:]
    var contentOf: [(name: String, content: String)] = []
    /// progress is what the script reads to know a step has come to rest: the reads sent, held and
    /// withdrawn, and the layers the map draws.
    func progress() -> [String] {
      held.progress.map { "\($0)" } + map.state.layers.map(\.id)
    }
    for step in steps {
      switch try step.string(at: "step") {
      case "request":
        let content = try step.string(at: "content")
        let name = try step.string(at: "request")
        contentOf.append((name, content))
        switch content {
        case "itinerary": calls[name] = MainQueue.run { _ = try await map.setItinerary(name) }
        case "collection": calls[name] = MainQueue.run { _ = try await map.setCollection(name) }
        default: throw FixtureError(description: "no content `\(content)` is asked for by id")
        }
      case "toggle":
        let content = try step.string(at: "content")
        let on = try step.flag(at: "on")
        contentOf.append((content, content))
        switch content {
        case "itineraries": _ = MainQueue.run { try await map.setItineraries(on) }
        case "zones": _ = MainQueue.run { try await map.setZones(on) }
        default: throw FixtureError(description: "no content `\(content)` is switched")
        }
      case "clear":
        switch try step.string(at: "content") {
        case "itinerary": map.clearItinerary()
        case "collection": map.clearCollection()
        case "itineraries": _ = MainQueue.run { try await map.setItineraries(false) }
        case "zones": _ = MainQueue.run { try await map.setZones(false) }
        case let other: throw FixtureError(description: "no content `\(other)` is cleared")
        }
      case "answer":
        let name = try step.string(at: "request")
        // A read withdrawn before its answer is no longer held, and the answer reaches nobody.
        if let read = held.reads.indices.first(where: {
          readName(held.reads[$0].request) == name && held.isHeld($0)
        }) {
          let line = OrderedJSON.object([
            OrderedJSON.Member(key: "id", value: .string("line-\(name)")),
            OrderedJSON.Member(key: "source_layer", value: .string("itinerary_lines")),
            OrderedJSON.Member(key: "type", value: .string("line")),
          ])
          try held.answer(
            read,
            body: try MapFixtures.specificationBody(
              MapFixtures.specification("source-\(name)", layers: [line])))
        }
      case "withdraw":
        calls[try step.string(at: "request")]?.cancel()
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      await MainQueue.settle { progress() }
    }
    var drawn: [String: String] = [:]
    for (name, content) in contentOf
    where map.state.layers.contains(where: { $0.id == "line-\(name)" }) {
      if let already = drawn[content], already != name {
        throw FixtureError(description: "the \(content) draws both \(already) and \(name)")
      }
      drawn[content] = name
    }
    let reads = held.reads.map { OrderedJSON.string(readName($0.request)) }
    held.release()
    await MainQueue.settle { progress() }
    map.close()
    return .value(
      .object([
        OrderedJSON.Member(
          key: "drawn",
          value: .object(
            ["collection", "itineraries", "itinerary", "zones"].map { content in
              OrderedJSON.Member(key: content, value: drawn[content].map { .string($0) } ?? .null)
            })),
        OrderedJSON.Member(key: "reads", value: .array(reads)),
      ]))
  }

  /// readName names a read by its path: the id a specification is asked for by, or the content a
  /// toggle reads, `itineraries` or `zones`.
  static func readName(_ request: ExchangeRequest) -> String {
    let parts = request.url.pathComponents.filter { $0 != "/" }
    guard let version = parts.firstIndex(of: "v1") else { return request.url.path }
    let rest = Array(parts[(version + 1)...])
    return rest.count == 3 ? rest[1] : (rest.first ?? request.url.path)
  }
}

extension MapFixtures {
  /// stampedOverlay builds an overlay of `map.overlays.instant`'s manifest: its `slug`, its
  /// `capabilities` from `server` and `client`, and one vector source, `<slug>-source`, drawn from
  /// its `tiles`, of one fill layer at every zoom, `<slug>-layer`.
  static func stampedOverlay(_ written: OrderedJSON) throws(FixtureError) -> TileSchema.Overlay {
    let slug = try written.string(at: "slug")
    var overlay = GeoTileFixtures.overlay(slug, id: slug)
    overlay.capabilities = TileSchema.OverlayCapabilities(
      client: TileSchema.OverlaySupportedCapabilities(timestamp: try written.flag(at: "client")),
      server: TileSchema.OverlaySupportedCapabilities(timestamp: try written.flag(at: "server")))
    overlay.sources = [
      TileSchema.TileSource(
        id: "\(slug)-source",
        layers: [
          TileSchema.TileLayer(
            id: "\(slug)-layer", key: slug, layout: nil, paint: nil, source_layer: slug,
            type: .fill, zoom_max: 22, zoom_min: 0)
        ], tiles: try GeoFixtures.textList(written, at: "tiles"), type: .vector, zoom_max: 22,
        zoom_min: 0)
    ]
    return overlay
  }

  /// Serving is an exchange that answers every request at once, with the status and the body its
  /// answer gives for it, and records each one.
  actor Serving: HTTPExchange {
    let answer: @Sendable (ExchangeRequest) -> (Int, Data)
    private(set) var sent: [ExchangeRequest] = []

    init(answer: @escaping @Sendable (ExchangeRequest) -> (Int, Data)) {
      self.answer = answer
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent.append(request)
      let (status, body) = answer(request)
      return ExchangeResponse(
        status: status, headers: ["Content-Type": "application/json"], body: ExchangeBody(body))
    }
  }
}
