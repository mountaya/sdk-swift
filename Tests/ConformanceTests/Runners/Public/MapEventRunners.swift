import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapEventsPointer answers what a map tells of the case's gestures, through the engine's
  /// `events()` on the scripted surface, which plays each `click` as a tap and each `contextmenu`
  /// as a long tap, the features `under` the pointer being what the surface draws there. A gesture
  /// the case says an edit took is played while a waypoint is being placed, the edit Swift's map
  /// takes a gesture with. A `tap` is told as `click`, a `longTap` as `contextmenu` and a
  /// `featureTap` as `featureclick`.
  static let mapEventsPointer = Runner(id: "map.events.pointer", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    var read:
      [(gesture: String, point: [Double], position: [Double], under: [QueriedFeature], taken: Bool)] =
        []
    for step in try input.array(at: "steps") {
      read.append(
        (
          try step.string(at: "step"), try step.numbers(at: "point"),
          try step.numbers(at: "lngLat"),
          try MapFixtures.features(step, at: "under"), try step.flag(at: "taken")
        ))
    }
    let steps = read
    return try await MapFixtures.telling(input) { map, surface in
      for step in steps {
        surface.rendered = step.under
        if step.taken {
          try map.beginWaypointEdit("taking")
        }
        switch step.gesture {
        case "click": surface.tap(at: step.point, position: step.position)
        case "contextmenu": surface.longTap(at: step.point, position: step.position)
        default: throw FixtureError(description: "no gesture is called `\(step.gesture)`")
        }
        if step.taken {
          map.endWaypointEdit()
        }
      }
    } answering: { event in
      switch event {
      case .tap(let tap):
        return MapFixtures.gesture("click", tap: tap)
      case .longTap(let tap):
        return MapFixtures.gesture("contextmenu", tap: tap)
      case .featureTap(let position, let features):
        return .object([
          OrderedJSON.Member(key: "event", value: .string("featureclick")),
          OrderedJSON.Member(key: "features", value: .array(try features.map(MapFixtures.answer))),
          OrderedJSON.Member(key: "lngLat", value: GeoFixtures.numbers(position)),
        ])
      default:
        throw FixtureError(description: "a gesture told \(event)")
      }
    }
  }

  /// mapEventsFeatureHover answers what a map tells as a hovering pointer moves over it, through
  /// the engine's `events()` on the scripted surface, which plays each `move` as a pointer hovering
  /// at its point, the features `under` it being what the surface draws there, each `frame` as the
  /// next frame drawn and each `leave` as the pointer leaving the canvas. The bands a hover reads are
  /// held to `LayerRank`'s.
  static let mapEventsFeatureHover = Runner(id: "map.events.feature-hover", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "bands": .object([
          OrderedJSON.Member(
            key: "itineraryLine", value: .number(Double(LayerRank.itineraryLine.rank))),
          OrderedJSON.Member(
            key: "itineraryPoint", value: .number(Double(LayerRank.itineraryPoint.rank))),
        ])
      ])
    let input = fixtureCase.input
    let steps = try input.array(at: "steps")
    return try await MapFixtures.telling(input) { _, surface in
      for step in steps {
        switch try step.string(at: "step") {
        case "move":
          surface.rendered = try MapFixtures.features(step, at: "under")
          surface.hover(at: try step.numbers(at: "point"), position: try step.numbers(at: "lngLat"))
        case "frame":
          surface.drawFrame()
        case "leave":
          surface.leave(at: try step.numbers(at: "point"), position: try step.numbers(at: "lngLat"))
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
      }
    } answering: { event in
      guard case .featureHover(let position, let features) = event else {
        throw FixtureError(description: "a hover told \(event)")
      }
      return .object([
        OrderedJSON.Member(key: "features", value: .array(try features.map(MapFixtures.answer))),
        OrderedJSON.Member(key: "lngLat", value: GeoFixtures.numbers(position)),
      ])
    }
  }

  /// mapEventsAccessRefused answers how a failure of one of the map's own requests is told,
  /// through the engine's `events()`. The layers manifest's read is the engine's own, for the base
  /// map `setTerrain(_:)` asks for, through a client reaching the Tile API at the case's `tilesBaseUrl`,
  /// whose exchange answers its status, or fails with none; a renderer's request is played on the
  /// scripted surface, a status written as text being one that is no number, which a renderer
  /// reports as none, under the credential `sentUnder` names, `superseded` played as a request
  /// that left under one the client no longer sends. The refusing statuses are held to those the
  /// engine tells as refusals, every status from 100 to 599 played, and the manifest's path to the
  /// one a refusal of it is told at.
  ///
  /// A case stating `pageOrigin` plays on that page: the client reaches the Tile API at the origin
  /// and `tilesBaseUrl` joined, which no client takes as a path alone, and an address told on that
  /// origin is read relative to it. A renderer's request whose `credential` is
  /// `unreadable` never leaves, so the renderer reports it with no status, which is what its request
  /// hook does; one whose style is asked for `again` is reported a second time, under the
  /// credential `again` names.
  static let mapEventsAccessRefused = Runner(id: "map.events.access-refused", table: .public) {
    fixture, fixtureCase in
    let refusing = try await MapFixtures.refusingStatuses()
    let manifestPath = try await MapFixtures.manifestPath()
    try fixture.holdConstants(
      [:],
      values: [
        "manifestPath": .string(manifestPath),
        "refusalStatuses": .array(refusing.map { .number(Double($0)) }),
      ])
    let input = fixtureCase.input
    guard let failure = input["failure"] else {
      throw FixtureError(description: "the input states no `failure`")
    }
    let status = failure["status"]?.numberValue.flatMap { Int(exactly: $0) }
    let tilesBaseUrl = try input.string(at: "tilesBaseUrl")
    let page = try input.optionalString(at: "pageOrigin")
    guard let tiles = URL(string: (page ?? "") + tilesBaseUrl) else {
      throw FixtureError(description: "`\(tilesBaseUrl)` is no address")
    }
    /// onPage is an address told on the page's origin read relative to it, the origin taken off.
    func onPage(_ url: String) -> String {
      guard let page, url.hasPrefix(page + "/") else { return url }
      return String(url.dropFirst(page.count))
    }
    let request = try failure.string(at: "request")
    let url = try failure.optionalString(at: "url")
    let superseded = try MapFixtures.isSuperseded(failure)
    let unreadable: Bool
    switch try failure.optionalString(at: "credential") {
    case nil: unreadable = false
    case "unreadable": unreadable = true
    case let other?: throw FixtureError(description: "no credential is `\(other)`")
    }
    let again = try failure.optionalString(at: "again").map { written throws(FixtureError) in
      try MapFixtures.isSuperseded(
        .object([OrderedJSON.Member(key: "sentUnder", value: .string(written))]))
    }
    let told = try await MapFixtures.told { () throws -> MapEngine in
      let exchange = MapFixtures.Recording(answer: status.map { .status($0) } ?? .failing)
      return MapEngine(
        client: try MapFixtures.client(baseUrls: BaseURLs(tiles: tiles), exchange: exchange),
        geolocation: InertGeolocation())
    } playing: { map, surface in
      switch request {
      case "manifest": try? await map.setTerrain()
      case "renderer" where unreadable:
        surface.failRequest(url: url, status: nil, source: nil)
      case "renderer":
        surface.failRequest(url: url, status: status, source: nil, superseded: superseded)
        if let again {
          surface.failRequest(url: url, status: status, source: nil, superseded: again)
        }
      default: throw FixtureError(description: "no request is called `\(request)`")
      }
    }
    var refused: OrderedJSON = .null
    var error = false
    for event in told {
      switch event {
      case .accessRefused(let status, let url):
        guard refused.isNull else { throw FixtureError(description: "two refusals were told") }
        refused = .object([
          OrderedJSON.Member(key: "status", value: .number(Double(status))),
          OrderedJSON.Member(key: "url", value: .string(onPage(url))),
        ])
      case .failure:
        error = true
      default:
        throw FixtureError(description: "a failure told \(event)")
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "accessRefused", value: refused),
        OrderedJSON.Member(key: "error", value: .bool(error)),
      ]))
  }

  /// mapEventsAccessStanding answers whether a refusal of access stands after each of the case's
  /// steps, which the engine's `state.isAccessRequired` reads, and whether that step ended the last
  /// one standing, which its `events()` tells as `accessRestored`. Each step is played on the
  /// scripted surface, the style holding the sources `held` names as it arrives: a refusal as a
  /// renderer's request refused the `status` the step states, a 402 where it states none, for the
  /// source named, or none, under the credential `sentUnder` names, a tile as a tile of its source
  /// loading and a style as one loading. A tap on the canvas after each step marks where it ends in
  /// the events told, which a standing refusal neither starts nor ends.
  static let mapEventsAccessStanding = Runner(id: "map.events.access-standing", table: .public) {
    _, fixtureCase in
    let (standing, told) = try await MapFixtures.standing(
      after: try fixtureCase.input.array(at: "steps"))
    var restored: [Bool] = []
    var restoredInStep = false
    for event in told {
      switch event {
      case .tap:
        restored.append(restoredInStep)
        restoredInStep = false
      case .accessRestored:
        guard !restoredInStep else { throw FixtureError(description: "an end was told twice") }
        restoredInStep = true
      case .accessRefused:
        continue
      default:
        throw FixtureError(description: "a step told \(event)")
      }
    }
    guard restored.count == standing.count else {
      throw FixtureError(description: "\(standing.count) steps, and \(restored.count) were marked")
    }
    return .value(
      .array(
        zip(restored, standing).map { restored, standing in
          .object([
            OrderedJSON.Member(key: "restored", value: .bool(restored)),
            OrderedJSON.Member(key: "standing", value: .bool(standing)),
          ])
        }))
  }
}

extension MapFixtures {
  /// standing plays the access steps on an engine drawn on the scripted surface, and answers
  /// whether a refusal stands after each, and every event told, a tap marking each step's end.
  @MainActor
  static func standing(after steps: [OrderedJSON]) async throws -> (
    standing: [Bool], told: [MapEvent]
  ) {
    let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
    let surface = ScriptedMapSurface(drawing: map)
    let events = map.events()
    var standing: [Bool] = []
    for (index, step) in steps.enumerated() {
      if step["held"] != nil {
        surface.heldSources = try GeoFixtures.textList(step, at: "held")
      }
      switch try step.string(at: "step") {
      case "refused":
        let status = try step["status"] == nil ? 402 : step.integer(at: "status")
        surface.failRequest(
          url: "https://tiles.test/x", status: status,
          source: try step.optionalString(at: "source"), superseded: try isSuperseded(step))
      case "tile":
        surface.loadTile(of: try step.string(at: "source"))
      case "style":
        surface.loadStyle()
      case "givenBack":
        // A switch asked for, its document not arriving, and the base map shown before it given
        // back and loaded anew.
        guard let switched = URL(string: "https://tiles.test/switch-\(index).json") else {
          throw FixtureError(description: "no address for the switch")
        }
        map.setStyle(switched)
        surface.failStyle()
        surface.loadStyle()
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      standing.append(map.state.isAccessRequired)
      surface.tap(at: [-1, -1], position: [0, 0])
    }
    map.close()
    var told: [MapEvent] = []
    for await event in events {
      told.append(event)
    }
    return (standing, told)
  }

  /// isSuperseded reads the credential a renderer's request left with, `sentUnder`: `current`, the
  /// one the client sends as the answer arrives, which a failure stating none left with too, or
  /// `superseded`, one the client no longer sends.
  static func isSuperseded(_ failure: OrderedJSON) throws(FixtureError) -> Bool {
    switch try failure.optionalString(at: "sentUnder") {
    case nil, "current": false
    case "superseded": true
    case let other?: throw FixtureError(description: "no credential is sent under `\(other)`")
    }
  }

  /// gesture writes a tap or a long tap as the fixtures expect the event, `{ event, lngLat, point }`.
  static func gesture(_ name: String, tap: MapTap) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "event", value: .string(name)),
      OrderedJSON.Member(key: "lngLat", value: GeoFixtures.numbers(tap.position)),
      OrderedJSON.Member(key: "point", value: GeoFixtures.numbers(tap.point)),
    ])
  }

  /// telling plays `play` on an engine drawn on the scripted surface, the case's layers placed, and
  /// answers every event it told, each written by `answer`, in order.
  static func telling(
    _ input: OrderedJSON,
    playing play: @MainActor (MapEngine, ScriptedMapSurface) throws -> Void,
    answering answer: (MapEvent) throws -> OrderedJSON
  ) async throws -> RunnerOutcome {
    let told = try await Self.told {
      MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
    } playing: { map, surface in
      try MapFixtures.place(input, on: map)
      try play(map, surface)
    }
    return .value(.array(try told.map(answer)))
  }

  /// told plays `play` on the engine `make` builds, drawn on the scripted surface, and answers
  /// every event it told, in order, read once the engine is closed and its stream ended.
  @MainActor
  static func told(
    _ make: @MainActor () throws -> MapEngine,
    playing play: @MainActor (MapEngine, ScriptedMapSurface) async throws -> Void
  ) async throws -> [MapEvent] {
    let map = try make()
    let surface = ScriptedMapSurface(drawing: map)
    let events = map.events()
    try await play(map, surface)
    map.close()
    var told: [MapEvent] = []
    for await event in events {
      told.append(event)
    }
    return told
  }

  /// refusingStatuses is every status from 100 to 599 the engine tells, failing a renderer's
  /// request, as a refusal of access.
  @MainActor
  static func refusingStatuses() async throws -> [Int] {
    var refusing: [Int] = []
    for status in 100...599 {
      let told = try await told {
        MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      } playing: { _, surface in
        surface.failRequest(url: "https://tiles.test/x", status: status, source: nil)
      }
      if case .accessRefused? = told.first {
        refusing.append(status)
      }
    }
    return refusing
  }

  /// manifestPath is the path a refusal of the layers manifest is told at, past the Tile API's
  /// address.
  @MainActor
  static func manifestPath() async throws -> String {
    let base = "https://tiles.test"
    let told = try await told {
      MapEngine(
        client: try MapFixtures.client(
          baseUrls: BaseURLs(tiles: URL(string: base) ?? BaseURLs.standard.tiles),
          exchange: Recording(answer: .status(403))),
        geolocation: InertGeolocation())
    } playing: { map, _ in
      try? await map.setTerrain()
    }
    guard case .accessRefused(_, let url)? = told.first, url.hasPrefix(base) else {
      throw FixtureError(description: "a refused manifest told \(told)")
    }
    return String(url.dropFirst(base.count))
  }
}
