import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapCameraPose answers what a camera move hands the renderer, through the engine a consumer
  /// drives and the published scripted surface, which records each move: the members the case's
  /// `pose` states, each `unstated` member left nil, which is how a Swift caller forwards a member
  /// it may not have. A member a `CameraTarget` cannot hold, a centre written as an object or a
  /// pitch written as text, is refused by the type before any call, as the kind the fixture names
  /// for that member. A refused move hands the renderer nothing.
  static let mapCameraPose = Runner(id: "map.camera.pose", table: .public) { _, fixtureCase in
    let input = fixtureCase.input
    let unstated = Set(
      input["unstated"] == nil ? [] : try GeoFixtures.textList(input, at: "unstated"))
    let pose = input["pose"] ?? .object([])
    var target = CameraTarget()
    if let center = pose["center"], !unstated.contains("center") {
      guard let numbers = try? center.numberList(naming: "center") else {
        return .value(MapFixtures.refusedPose("position-refused"))
      }
      target.center = numbers
    }
    for member in ["zoom", "bearing", "pitch"] where !unstated.contains(member) {
      guard let written = pose[member] else { continue }
      guard let number = written.numberValue else {
        return .value(MapFixtures.refusedPose("number-refused"))
      }
      switch member {
      case "zoom": target.zoom = number
      case "bearing": target.bearing = number
      default: target.pitch = number
      }
    }
    let move = try input.string(at: "move")
    guard ["jump", "ease", "fly"].contains(move) else {
      throw FixtureError(description: "no camera move is called `\(move)`")
    }
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(drawing: map)
      do throws(MapError) {
        switch move {
        case "jump": try map.jump(to: target)
        case "ease": try map.ease(to: target)
        default: try map.fly(to: target)
        }
      } catch {
        guard surface.moves.isEmpty else {
          throw FixtureError(description: "a refused move handed the renderer a move")
        }
        return .value(MapFixtures.refusedPose(MapFixtures.kind(error)))
      }
      guard surface.moves.count == 1, let handed = surface.moves.first?.target else {
        throw FixtureError(description: "the move handed the renderer \(surface.moves.count) moves")
      }
      return .value(
        .object([
          OrderedJSON.Member(key: "pose", value: MapFixtures.target(handed)),
          OrderedJSON.Member(key: "refused", value: .null),
        ]))
    }
  }

  /// mapCameraFitOptions answers what a drawing call frames its content with, through the
  /// engine's `setCollection(_:fit:)`, over an exchange answering a collection's specification
  /// stating a box, and the scripted surface, which records each box it is asked to frame: `true`
  /// is a fit stating nothing, `false` and a fit left out are none, and options are a `CameraFit` of
  /// the members they state, each `unstated` member left nil. A fit that is neither a boolean nor
  /// options cannot be handed to the call at all, and a padding, a ceiling or a duration a
  /// `CameraFit` cannot hold, text or a duration of no finite length, are refused by the type
  /// before any call. A refused fit reads nothing, which the runner holds to. The options framed
  /// with are written as the case wrote them, a padding of one number for every edge as that
  /// number.
  static let mapCameraFitOptions = Runner(id: "map.camera.fit-options", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let unstated = Set(
      input["unstated"] == nil ? [] : try GeoFixtures.textList(input, at: "unstated"))
    let fit: CameraFit?
    switch MapFixtures.readFit(input["fit"], unstated: unstated) {
    case .refused(let kind):
      return .value(MapFixtures.fitAnswer(drawn: false, fit: nil, refused: kind))
    case .read(let read):
      fit = read
    }
    let body = try MapFixtures.specificationBody(MapFixtures.collection)
    let exchange = MapFixtures.Serving { _ in (200, body) }
    let paddingAsOne = input["fit"]?["padding"]?.numberValue != nil
    return try await MapFixtures.framedCollection(
      fit: fit, exchange: exchange, paddingAsOne: paddingAsOne)
  }

  /// mapCameraZoomWindow answers how a map's zoom window moves, call by call, through the engine's
  /// `setZoomBounds(min:max:)` on the scripted surface playing the renderer the case names, its
  /// `floor` and `ceiling`, the window `held` set first: a limit left out is kept, one written null
  /// released, one a number moved to it, and one written as text is refused by the type before any
  /// call. A call is told where it reported a state, which an engine does only where the state
  /// moved, and the stream it reports to is held to one state for each such call. MapLibre Native's
  /// limits are held to the engine's own on no surface, the state a map opens with and the window a
  /// release goes back to; MapLibre GL JS's are what the cases that name them play on.
  static let mapCameraZoomWindow = Runner(id: "map.camera.zoom-window", table: .public) {
    fixture, fixtureCase in
    let input = fixtureCase.input
    let native = try await MainActor.run {
      () throws -> (opened: ZoomBounds, released: ZoomBounds) in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      let opened = map.state.zoomBounds
      try map.setZoomBounds(min: 4, max: 6)
      try map.setZoomBounds(min: .released, max: .released)
      return (opened, map.state.zoomBounds)
    }
    guard native.opened == native.released else {
      throw FixtureError(
        description: "a map opens on \(native.opened), and releases to \(native.released)")
    }
    try fixture.holdConstants(
      [:],
      values: [
        "maplibreNative": .object([
          OrderedJSON.Member(key: "ceiling", value: .number(native.released.maxZoom)),
          OrderedJSON.Member(key: "floor", value: .number(native.released.minZoom)),
        ])
      ], inputs: ["maplibreGlJs"])
    let renderer = ZoomBounds(
      minZoom: try input.number(at: "floor"), maxZoom: try input.number(at: "ceiling"))
    let held = try GeoCameraFixtures.window(input, at: "held")
    let calls = try input.array(at: "calls")
    return try await playZoomWindow(renderer: renderer, held: held, calls: calls)
  }

  /// playZoomWindow plays the case's calls on an engine drawn on a surface playing `renderer`.
  @MainActor
  private static func playZoomWindow(renderer: ZoomBounds, held: ZoomBounds, calls: [OrderedJSON])
    async throws -> RunnerOutcome
  {
    let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
    let surface = ScriptedMapSurface(drawing: map, zoomLimits: renderer)
    try map.setZoomBounds(min: .zoom(held.minZoom), max: .zoom(held.maxZoom))
    let states = map.subscribe()
    var answers: [OrderedJSON] = []
    var told = 0
    for call in calls {
      let before = map.state
      var refused: String?
      if let min = MapFixtures.limit(call["min"]), let max = MapFixtures.limit(call["max"]) {
        do throws(MapError) {
          try map.setZoomBounds(min: min, max: max)
        } catch {
          refused = MapFixtures.kind(error)
        }
      } else {
        refused = "number-refused"
      }
      let moved = map.state != before
      told += moved ? 1 : 0
      answers.append(
        .object([
          OrderedJSON.Member(key: "refused", value: refused.map { .string($0) } ?? .null),
          OrderedJSON.Member(key: "told", value: .bool(moved)),
          OrderedJSON.Member(
            key: "window", value: GeoCameraFixtures.windowAnswer(map.state.zoomBounds)),
        ]))
    }
    map.close()
    var reported = -1
    for await _ in states {
      reported += 1
    }
    guard reported == told else {
      throw FixtureError(
        description: "\(told) calls moved the window, and \(reported) states were told")
    }
    withExtendedLifetime(surface) {}
    return .value(.array(answers))
  }

  /// mapCameraControlMoves answers where a map control moves the camera, through the engine's
  /// `zoomIn()`, `zoomOut()` and `resetNorth()`, on the scripted surface playing a renderer whose
  /// floor lets the case's window be held: the camera the case states, held to its window, moved,
  /// and the camera the state then holds. The renderer is handed only the members that move.
  static let mapCameraControlMoves = Runner(id: "map.camera.control-moves", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    guard let camera = input["camera"] else {
      throw FixtureError(description: "the input states no `camera`")
    }
    let pose = CameraPose(
      center: try camera.numbers(at: "center"), zoom: try camera.number(at: "zoom"),
      pitch: try camera.number(at: "pitch"), bearing: try camera.number(at: "bearing"))
    let window = try GeoCameraFixtures.window(input, at: "window")
    let move = try input.string(at: "move")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(
        client: try MapFixtures.client(), camera: pose, geolocation: InertGeolocation())
      let surface = ScriptedMapSurface(
        drawing: map, zoomLimits: ZoomBounds(minZoom: -2, maxZoom: 22))
      try map.setZoomBounds(min: .zoom(window.minZoom), max: .zoom(window.maxZoom))
      let handed: Set<String>
      switch move {
      case "zoom-in":
        map.zoomIn()
        handed = ["zoom"]
      case "zoom-out":
        map.zoomOut()
        handed = ["zoom"]
      case "reset-north":
        map.resetNorth()
        handed = ["bearing", "pitch"]
      default:
        throw FixtureError(description: "no control moves `\(move)`")
      }
      guard let moved = surface.moves.last?.target,
        Set(MapFixtures.target(moved).members?.map(\.key) ?? []) == handed
      else {
        throw FixtureError(description: "the renderer was handed \(surface.moves)")
      }
      return .value(MapFixtures.camera(map.state.camera))
    }
  }

  /// mapCameraLocate answers what locating does, through the engine's `locate()` over a
  /// geolocation of the runner's own, answering the case's `fix` and recording whether it was
  /// asked, and the scripted surface, which records the box the camera is asked to frame and the
  /// fit's ceiling. A map the case closes is closed before it locates. The ceiling is held to the
  /// published `locateMaxZoom`, and the device's own geolocation's fix age and wait to the
  /// published `locateMaxFixAge` and `locateFixWait`.
  static let mapCameraLocate = Runner(id: "map.camera.locate", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "fixWaitMs": GeoSearchEngineFixtures.milliseconds(locateFixWait),
      "maxFixAgeMs": GeoSearchEngineFixtures.milliseconds(locateMaxFixAge),
      "maxZoom": locateMaxZoom,
    ])
    let input = fixtureCase.input
    guard let written = input["fix"] else {
      throw FixtureError(description: "the input states no `fix`")
    }
    let fix: GeolocationFix
    if try written.flag(at: "ok") {
      fix = .located(
        position: try written.numbers(at: "position"),
        accuracyMeters: try written.number(at: "accuracyMeters"))
    } else {
      let reason = try written.string(at: "reason")
      guard let refusal = GeolocationRefusal(rawValue: reason) else {
        throw FixtureError(description: "`\(reason)` is no reason a geolocation refuses with")
      }
      fix = .refused(refusal)
    }
    let closed = try input.flag(at: "closed")
    return try await locating(fix, closed: closed)
  }

  /// locating locates the device on an engine whose geolocation answers `fix`, closed first where
  /// `closed` says so.
  @MainActor
  private static func locating(_ fix: GeolocationFix, closed: Bool) async throws -> RunnerOutcome {
    let geolocation = MapFixtures.Fix(answer: fix)
    let map = MapEngine(client: try MapFixtures.client(), geolocation: geolocation)
    let surface = ScriptedMapSurface(drawing: map)
    if closed {
      map.close()
    }
    var refused: OrderedJSON = .null
    var reason: OrderedJSON = .null
    do throws(MapError) {
      try await map.locate()
    } catch {
      refused = .string(MapFixtures.kind(error))
      if case .fixRefused(let named) = error.kind {
        reason = .string(named.rawValue)
      }
    }
    let framed: OrderedJSON =
      surface.frames.last.map { frame in
        .object([
          OrderedJSON.Member(key: "bounds", value: GeoFixtures.numbers(frame.bounds)),
          OrderedJSON.Member(
            key: "maxZoom", value: frame.fit.maxZoom.map { .number($0) } ?? .null),
        ])
      } ?? .null
    return .value(
      .object([
        OrderedJSON.Member(key: "asked", value: .bool(geolocation.asked)),
        OrderedJSON.Member(key: "framed", value: framed),
        OrderedJSON.Member(key: "reason", value: reason),
        OrderedJSON.Member(key: "refused", value: refused),
      ]))
  }
}

extension MapFixtures {
  /// framedCollection draws a collection's specification through `setCollection(_:fit:)` with
  /// `fit`, and answers what the call drew and framed it with.
  @MainActor
  static func framedCollection(fit: CameraFit?, exchange: Serving, paddingAsOne: Bool)
    async throws -> RunnerOutcome
  {
    let map = MapEngine(client: try client(exchange: exchange), geolocation: InertGeolocation())
    let surface = ScriptedMapSurface(drawing: map)
    let drawn: Bool
    do {
      drawn = try await map.setCollection("c", fit: fit)
    } catch let error as MapError {
      guard map.state.layers.isEmpty, surface.frames.isEmpty, await exchange.sent.isEmpty else {
        throw FixtureError(description: "a refused fit read, drew or framed something")
      }
      return .value(fitAnswer(drawn: false, fit: nil, refused: kind(error)))
    }
    guard surface.frames.count <= 1 else {
      throw FixtureError(description: "the call framed its content more than once")
    }
    let framed = surface.frames.first.map { fitOptions($0.fit, paddingAsOne: paddingAsOne) }
    return .value(fitAnswer(drawn: drawn, fit: framed ?? .null, refused: nil))
  }
}
