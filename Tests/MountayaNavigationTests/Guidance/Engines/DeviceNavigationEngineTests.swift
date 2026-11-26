import MountayaClient
import MountayaGeo
import MountayaNavigation
import Observation
import Testing

/// The engine an app navigates with, on every host the package builds on: its states are Geo's
/// machine's, its location source and its voice are driven by what the machine decides, and each
/// prompt is said at the meter Geo's progress names, as `sdk-dart`'s engine says it.
@Suite("DeviceNavigationEngine")
@MainActor
struct DeviceNavigationEngineTests {
  /// eastward is two stretches east along the equator, about 2.2 km, followed as a departure and
  /// an arrival.
  private static let eastward = NavigationRoute(
    line: [[0, 0], [0.01, 0], [0.02, 0]], duration: 1_200)
  /// detour leaves from 200 m north of the eastward route's middle and rejoins it at its end.
  private static let detour = NavigationRoute(line: [[0.01, 0.0018], [0.02, 0]], duration: 900)
  /// turning departs east for about 1.1 km, turns north onto a path for as long, and arrives at
  /// its end.
  private static let turning = NavigationRoute(
    line: [[0, 0], [0.01, 0], [0.01, 0.01]],
    steps: [
      NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Chemin"),
      NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .turnLeft, name: "Sentier"),
      NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal),
    ])

  /// north is a position this many meters north of the equator at a longitude.
  private func north(_ meters: Double, atLongitude longitude: Double) -> [Double] {
    [longitude, meters / metersPerDegreeMeanSphere]
  }

  /// beforeTurn is a position this many meters west of the turning route's turn, on its first
  /// step.
  private func beforeTurn(_ meters: Double) -> [Double] {
    [0.01 - meters / metersPerDegreeMeanSphere, 0]
  }

  /// Asked keeps every request a route source was asked for, in order.
  @MainActor
  private final class Asked {
    var requests: [String] = []
  }

  private struct NoRoute: Error {}

  /// source answers `routes` by request, in a turn of its own, and keeps each request in `asked`.
  private func source(_ routes: [String: NavigationRoute], asked: Asked = Asked())
    -> NavigationRouteSource<String>
  {
    { @MainActor request in
      asked.requests.append(request)
      guard let route = routes[request] else { throw NoRoute() }
      return route
    }
  }

  /// landed waits for the route the engine asked for to land, which the guidance has followed
  /// before any stream is handed it.
  private func landed(_ engine: DeviceNavigationEngine<String>) async {
    _ = await settled(engine.subscribe(), at: .navigating)
  }

  @Test("its states are the scripted engine's for the same journey, a reroute and an arrival in it")
  func statesAreTheScriptedEngines() async throws {
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward, "from-here": Self.detour]))
    let scripted = ScriptedNavigationEngine<String>()
    let fromDevice = device.subscribe()
    let fromScripted = scripted.subscribe()

    device.start("summit")
    scripted.start("summit")
    await landed(device)
    try scripted.sent[0].answer(Self.eastward)
    for position in [north(10, atLongitude: 0.005), north(200, atLongitude: 0.01)] {
      try device.setPosition(position)
      try scripted.setPosition(position)
    }
    device.reroute("from-here")
    scripted.reroute("from-here")
    await landed(device)
    try scripted.sent[1].answer(Self.detour)
    try device.setPosition([0.02, 0])
    try scripted.setPosition([0.02, 0])
    device.stop()
    scripted.stop()
    device.close()
    scripted.close()

    let states = await recorded(fromDevice)
    #expect(states == (await recorded(fromScripted)))
    #expect(
      states.map(\.status) == [
        .idle, .routing, .navigating, .navigating, .offRoute, .rerouting, .navigating, .navigating,
        .arrived, .idle,
      ])
  }

  @Test("a route followed fix by fix is the machine's, state for state, off it and back included")
  func journeyFixByFix() async throws {
    let routes = ["summit": Self.eastward, "from-here": Self.detour]
    let device = DeviceNavigationEngine<String>(route: source(routes))
    let machine = RouteFollowingEngine<String>(route: source(routes))

    device.start("summit")
    machine.start("summit")
    await landed(device)
    _ = await settled(machine.subscribe(), at: .navigating)
    #expect(device.state == machine.state)

    let along = walk(Array(Self.eastward.line[0...1]), every: 10)
    #expect(along.count > 100, "a fix every 10 m along the first stretch")
    for position in along {
      try device.setPosition(position)
      try machine.setPosition(position)
      #expect(device.state == machine.state)
    }
    #expect(device.state.status == .navigating)

    try device.setPosition(north(200, atLongitude: 0.01))
    try machine.setPosition(north(200, atLongitude: 0.01))
    #expect(device.state.status == .offRoute)
    device.reroute("from-here")
    machine.reroute("from-here")
    #expect(device.state == machine.state)
    await landed(device)
    _ = await settled(machine.subscribe(), at: .navigating)
    #expect(device.state == machine.state)

    for position in walk(Self.detour.line, every: 10) {
      try device.setPosition(position)
      try machine.setPosition(position)
      #expect(device.state == machine.state)
    }
    #expect(device.state.status == .arrived)
    device.close()
    machine.close()
  }

  @Test(
    "the location source runs from the first start to a stop, and each position it states is read")
  func locationRuns() async throws {
    let location = RecordingLocationSource()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward]), location: location)

    device.start("summit")
    device.start("summit")
    #expect(location.started == 1)
    await landed(device)
    #expect(try location.state(north(10, atLongitude: 0.005)))
    #expect(device.state.progress?.along ?? 0 > 0)
    #expect(throws: PositionError.self, "a refused position is thrown back to the source") {
      try location.state([.nan, 0])
    }

    device.stop()
    #expect(location.stopped == 1)
    #expect(try !location.state(north(10, atLongitude: 0.006)))
    device.start("summit")
    #expect(location.started == 2)
    device.close()
    #expect(location.stopped == 2)
  }

  @Test(
    "the source is told of each route once the engine follows it, and of none where it follows none"
  )
  func sourceToldOfEachRoute() async throws {
    let location = RecordingLocationSource()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward, "from-here": Self.detour]), location: location)

    device.start("summit")
    #expect(location.followed.isEmpty)
    await landed(device)
    #expect(location.followed == [device.state.route])
    #expect(location.followed.last??.line == Self.eastward.line)

    try device.setPosition(north(200, atLongitude: 0.01))
    device.reroute("from-here")
    await landed(device)
    #expect(location.followed.count == 2)
    #expect(location.followed.last??.line == Self.detour.line)

    device.start("summit")
    #expect(location.followed.last == .some(nil), "a new start follows no route until one lands")
    await landed(device)
    device.stop()
    #expect(location.followed.last == .some(nil))
    device.close()
  }

  /// The machine tells the guidance each state inline, before any stream, so whichever order the
  /// main actor resumes readers in, none reads a route the guidance does not follow yet.
  @Test("the guidance follows each route before any stream is handed it")
  func guidanceBeforeStreams() async throws {
    let location = RecordingLocationSource()
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward]), location: location, voice: voice)
    let streams = (0..<4).map { _ in device.subscribe() }

    device.start("summit")
    var readers: [Task<Bool, Never>] = []
    for states in streams {
      readers.append(
        Task { @MainActor in
          for await state in states where state.status == .navigating {
            return location.followed.last == .some(state.route) && voice.said.count == 1
          }
          return false
        })
    }
    for reader in readers {
      #expect(await reader.value, "the source was told of the route and its departure was said")
    }
    device.close()
  }

  @Test("a source that states a position as it is told of a route is read on that route")
  func eagerSource() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward]),
      location: EagerLocationSource(at: north(10, atLongitude: 0.005)), voice: voice)

    device.start("summit")
    await landed(device)

    #expect(device.state.status == .navigating)
    #expect(abs((device.state.progress?.along ?? 0) - 556) < 1)
    #expect(voice.said.map(\.key) == [.departPlain])
    device.close()
  }

  @Test("each maneuver is said once, in the order a route followed fix by fix reaches them")
  func promptsInOrder() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.turning]), voice: voice)

    device.start("summit")
    await landed(device)
    #expect(voice.said.map(\.key) == [.depart], "the departure is said as the route lands")
    for position in walk(Self.turning.line) {
      try device.setPosition(position)
    }

    #expect(device.state.status == .arrived)
    #expect(voice.said.map(\.key) == [.depart, .turnLeft, .goalPlain])
    #expect(voice.said.map(\.name) == ["Chemin", "Sentier", nil])
    device.close()
  }

  /// Every SDK reads the same distance, Geo's, so each prompt is said at the same position in all
  /// of them: the first whose distance to the end of its step, less the prompt's 50 m, is 5 m or
  /// less. `sdk-dart`'s engine is held to the same two positions.
  @Test("a maneuver is said 55 m before it, as the 50 m lead and its 5 m slack place it")
  func promptAtTheSameMeter() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.turning]), voice: voice)
    device.start("summit")
    await landed(device)

    try device.setPosition(beforeTurn(55.5))
    #expect(abs((device.state.progress?.toManeuver.distance ?? 0) - 55.5) < 0.01)
    #expect(voice.said.map(\.key) == [.depart])
    try device.setPosition(beforeTurn(54.5))
    #expect(voice.said.map(\.key) == [.depart, .turnLeft])

    // The arrival is announced by the same rule on the step that leads to it.
    let path = Self.turning.line[1...2].map { $0 }
    let length = routeLengthMeters(path)
    try device.setPosition(north(length - 55.5, atLongitude: 0.01))
    #expect(voice.said.count == 2)
    try device.setPosition(north(length - 54.5, atLongitude: 0.01))
    #expect(voice.said.map(\.key) == [.depart, .turnLeft, .goalPlain])
    device.close()
  }

  @Test("walked a meter at a time, the turn is said at the first fix Geo reads within 55 m of it")
  func promptAtTheFirstFixWithin() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.turning]), voice: voice)
    device.start("summit")
    await landed(device)

    var left: [Double] = []
    var saidAt: Int?
    for position in walk(Array(Self.turning.line[0...1]), every: 1) {
      try device.setPosition(position)
      left.append(try #require(device.state.progress?.toManeuver.distance))
      if voice.said.count > 1, saidAt == nil {
        saidAt = left.count - 1
      }
    }

    let said = try #require(saidAt)
    #expect(voice.said.map(\.key) == [.depart, .turnLeft])
    #expect(left[said] <= 55, "the turn is said within its 50 m and the 5 m of slack")
    #expect(said > 0 && left[said - 1] > 55, "and not at the fix before it, which Geo read farther")
    device.close()
  }

  @Test("nothing is said off the route, and the maneuver ahead is said once back on it")
  func silentOffTheRoute() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.turning]), voice: voice)
    device.start("summit")
    await landed(device)

    // 40 m before the turn, 80 m south of the way: the turn is due, and the traveller is off.
    try device.setPosition([beforeTurn(40)[0], -80 / metersPerDegreeMeanSphere])
    #expect(device.state.status == .offRoute)
    #expect(device.state.progress?.toManeuver.distance ?? 0 < 50)
    #expect(voice.said.map(\.key) == [.depart])

    try device.setPosition(beforeTurn(40))
    #expect(device.state.status == .navigating)
    #expect(voice.said.map(\.key) == [.depart, .turnLeft])
    try device.setPosition(beforeTurn(39))
    try device.setPosition(beforeTurn(39))
    #expect(voice.said.count == 2, "a prompt said along the route is not said again")
    device.close()
  }

  @Test("an off-route position asks for no route, and a reroute asks once, only when the host asks")
  func reroutesOnlyWhenAsked() async throws {
    let asked = Asked()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward, "from-here": Self.detour], asked: asked))

    device.start("summit")
    await landed(device)
    device.reroute("from-here")
    #expect(device.state.status == .navigating, "on the route, a reroute does nothing")

    for meters in [800.0, 400, 200] {
      try device.setPosition(north(meters, atLongitude: 0.01))
      #expect(device.state.status == .offRoute)
    }
    await Task.yield()
    #expect(asked.requests == ["summit"], "off the route, the engine asks for nothing itself")

    device.reroute("from-here")
    device.reroute("from-here")
    #expect(device.state.status == .rerouting)
    await landed(device)
    #expect(asked.requests == ["summit", "from-here"], "one reroute, asked once")
    #expect(device.state.route?.line == Self.detour.line)
    #expect(device.state.status == .navigating, "the detour leaves from where the traveller stands")
    device.close()
  }

  @Test(
    "a route that lands while a position is held says nothing until that position is read on it")
  func routeLandsAtAPositionHeld() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.turning]), voice: voice)

    device.start("summit")
    try device.setPosition(beforeTurn(30))
    await landed(device)

    #expect(device.state.progress?.step == 0, "the position held is read on the route")
    #expect(
      voice.said.map(\.key) == [.turnLeft],
      "read 30 m before the turn, the turn is the prompt standing, and the departure is passed over"
    )
    device.close()
  }

  @Test("a position the machine reads to the state it holds says nothing")
  func unmovedPositionSaysNothing() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.turning]), voice: voice)
    device.start("summit")
    await landed(device)
    try device.setPosition([0.005, 0])
    let held = device.state

    try device.setPosition([0.005, 0])
    #expect(device.state == held, "the machine committed nothing")
    #expect(voice.said.map(\.key) == [.depart])
    try device.setPosition(beforeTurn(33))
    #expect(voice.said.map(\.key) == [.depart, .turnLeft], "the next reading says what is due")
    device.close()
  }

  @Test("a new route hushes the voice and says its own prompts, and a stop and a close hush it too")
  func newRouteStopAndCloseHush() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward, "from-here": Self.detour]), voice: voice)

    device.start("summit")
    await landed(device)
    #expect(voice.hushed == 1)
    #expect(voice.said.map(\.key) == [.departPlain])

    try device.setPosition(north(200, atLongitude: 0.01))
    device.reroute("from-here")
    await landed(device)
    #expect(device.state.route?.line == Self.detour.line)
    #expect(voice.hushed == 2)
    #expect(
      voice.said.map(\.key) == [.departPlain, .departPlain],
      "the detour departs from where the traveller stands")

    device.stop()
    #expect(device.state == .idle)
    #expect(voice.hushed == 3)
    try device.setPosition([0.015, 0])
    #expect(voice.said.count == 2, "a stopped navigation says nothing")
    device.close()
    #expect(voice.hushed == 4)
  }

  @Test("a replay walks each route followed to its arrival, with no device location")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func replayToArrival() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward]),
      location: ReplayLocationSource(metersPerSecond: 50, clock: StepClock()), voice: voice)

    device.start("summit")
    let arrived = await settled(device.subscribe(), at: .arrived)

    #expect(arrived?.progress?.toArrival.distance == 0)
    #expect(voice.said.map(\.key) == [.departPlain, .goalPlain])
    device.close()
  }

  /// The arrival is Geo's: raised where a position read on the route leaves no distance to its end,
  /// so a traveller who stops short never arrives and one at the end's foot but off the route has
  /// not arrived, as the machine answers for the same positions. The machine reads the position it
  /// holds as a route lands: a replay started again on the route it walked to its end states that
  /// route's start before the route is read, so the second walk is navigated from the start rather
  /// than arrived at once, or read ahead with its prompts passed.
  @Test("a replay walked to its arrival, stopped and started again walks the route from its start")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func replayRestarted() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward]),
      location: ReplayLocationSource(metersPerSecond: 50, clock: StepClock()), voice: voice)
    device.start("summit")
    _ = await settled(device.subscribe(), at: .arrived)
    device.stop()

    let again = device.subscribe()
    device.start("summit")
    var states: [NavigationState] = []
    for await state in again {
      states.append(state)
      if state.status == .arrived { break }
    }

    let read = states.compactMap(\.progress)
    #expect(read.first?.along == 0, "the second walk is read from the route's start")
    #expect(read.count > 2, "and walked to its end, fix by fix")
    #expect(states.last?.status == .arrived)
    #expect(voice.said.map(\.key) == [.departPlain, .goalPlain, .departPlain, .goalPlain])
    device.close()
  }

  @Test("two maneuvers on one vertex are said in order, the first 55 m out, the second at it")
  func twoManeuversOnOneVertex() async throws {
    let voice = RecordingVoice()
    let route = NavigationRoute(
      line: [[0, 0], [0.01, 0], [0.01, 0.01]],
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Chemin"),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .turnLeft, name: "Pont"),
        NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .turnRight, name: "Sentier"),
        NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal),
      ])
    let device = DeviceNavigationEngine<String>(route: source(["summit": route]), voice: voice)
    device.start("summit")
    await landed(device)

    #expect(voice.said.map(\.key) == [.depart], "the departure is said as the route lands")
    var saidAt: [Double] = []
    for position in walk(route.line, every: 1) {
      try device.setPosition(position)
      if voice.said.count > saidAt.count + 1, let progress = device.state.progress {
        saidAt.append(progress.toManeuver.distance)
      }
    }

    #expect(voice.said.map(\.key) == [.depart, .turnLeft, .turnRight, .goalPlain])
    #expect(voice.said.map(\.name) == ["Chemin", "Pont", "Sentier", nil])
    #expect(saidAt.count == 3)
    #expect(saidAt[0] <= 55 && saidAt[0] > 50, "the first maneuver 50 m out, as any other")
    #expect(saidAt[1] <= 5, "the second at the vertex the two share")
    device.close()
  }

  /// Of a step's prompts due, the last wins, and each is said once: of three maneuvers on one
  /// vertex, the first is said 50 m out and the last at the vertex, and the one between never is.
  @Test("of three maneuvers on one vertex, the first and the last are said")
  func threeManeuversOnOneVertex() async throws {
    let voice = RecordingVoice()
    let route = NavigationRoute(
      line: [[0, 0], [0.01, 0], [0.01, 0.01]],
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .turnLeft),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .turnRight),
        NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .continue),
        NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal),
      ])
    let device = DeviceNavigationEngine<String>(route: source(["summit": route]), voice: voice)
    device.start("summit")
    await landed(device)

    for position in walk(route.line) {
      try device.setPosition(position)
    }

    #expect(device.state.status == .arrived)
    #expect(voice.said.map(\.key) == [.departPlain, .turnLeftPlain, .continuePlain, .goalPlain])
    device.close()
  }

  @Test("a route opening with a step of no length says the maneuver after it as the walk begins")
  func zeroLengthFirstStep() async throws {
    let voice = RecordingVoice()
    let route = NavigationRoute(
      line: [[0, 0], [0, 0.01]],
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 0, maneuver: .depart, name: "Chemin"),
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .turnLeft, name: "Sentier"),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .goal),
      ])
    let device = DeviceNavigationEngine<String>(route: source(["summit": route]), voice: voice)
    device.start("summit")
    await landed(device)
    #expect(voice.said.isEmpty, "the departure covers no ground, and is not said")

    let positions = walk(route.line)
    try device.setPosition(positions[0])
    #expect(voice.said.map(\.key) == [.turnLeft], "the maneuver after it, as the walk begins")
    for position in positions.dropFirst() {
      try device.setPosition(position)
    }

    #expect(voice.said.map(\.key) == [.turnLeft, .goalPlain])
    device.close()
  }

  /// An observer of `state` is told of a change before it lands, on the main actor and inline: one
  /// that closes the engine as its start commits `routing` ends the start there.
  @Test("an engine closed by an observer as it starts starts no location source")
  func closedWhileStarting() async throws {
    let location = RecordingLocationSource()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward]), location: location)
    withObservationTracking {
      _ = device.state
    } onChange: {
      MainActor.assumeIsolated { device.close() }
    }

    device.start("summit")

    #expect(location.started == 0, "a closed engine starts no source, which nothing would stop")
    #expect(device.state.status == .routing)
    #expect(try !location.state([0, 0]))
  }

  @Test("the arrival is raised as Geo's rule raises it, and as the machine raises it")
  func arrivalAsGeosRule() async throws {
    let device = DeviceNavigationEngine<String>(route: source(["summit": Self.eastward]))
    let machine = RouteFollowingEngine<String>(route: source(["summit": Self.eastward]))
    device.start("summit")
    machine.start("summit")
    await landed(device)
    _ = await settled(machine.subscribe(), at: .navigating)

    let steps: [([Double], NavigationStatus)] = [
      ([0.02 - 1 / metersPerDegreeMeanSphere, 0], .navigating),
      ([0.02 + 100 / metersPerDegreeMeanSphere, 0], .offRoute),
      ([0.02, 0], .arrived),
    ]
    for (position, status) in steps {
      try device.setPosition(position)
      try machine.setPosition(position)
      #expect(device.state == machine.state)
      #expect(device.state.status == status)
    }
    #expect(device.state.progress?.toArrival.distance == 0)
    device.close()
    machine.close()
  }

  @Test("after a close every command does nothing, and the source states to nobody")
  func closed() async throws {
    let location = RecordingLocationSource()
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.eastward]), location: location, voice: voice)
    device.start("summit")
    await landed(device)
    device.close()
    let state = device.state
    let hushed = voice.hushed

    device.start("summit")
    try device.setPosition([.nan, 0])
    try device.setPosition([0.02, 0])
    device.reroute("summit")
    device.stop()
    device.close()

    #expect(device.state == state)
    #expect(location.started == 1)
    #expect(location.stopped == 1)
    #expect(try !location.state([0.02, 0]))
    #expect(voice.hushed == hushed)
    #expect(await recorded(device.subscribe()) == [state])
  }

  @Test("a position that names no place is refused by its value, and moves nothing")
  func refusedPosition() async throws {
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source(["summit": Self.turning]), voice: voice)
    device.start("summit")
    await landed(device)
    let before = device.state

    let refused = #expect(throws: PositionError.self) {
      try device.setPosition([.nan, 45.92])
    }
    #expect(refused?.position.last == 45.92)
    #expect(refused?.position.first?.isNaN == true)
    #expect(device.state == before)
    #expect(voice.said.count == 1)
    device.close()
  }

  @Test("a route that fails says nothing, and the source follows none")
  func failedRoute() async throws {
    let location = RecordingLocationSource()
    let voice = RecordingVoice()
    let device = DeviceNavigationEngine<String>(
      route: source([:]), location: location, voice: voice)

    device.start("nowhere")
    let failed = await settled(device.subscribe(), at: .failed)

    #expect(failed?.error?.kind == .routeFailed)
    #expect(failed?.error?.cause is NoRoute)
    #expect(location.followed.isEmpty)
    #expect(voice.said.isEmpty)
    device.close()
  }

  @Test("its defaults locate nothing and say nothing")
  func defaults() async throws {
    let device = DeviceNavigationEngine<String>(route: source(["summit": Self.turning]))

    device.start("summit")
    await landed(device)
    #expect(device.state.progress == nil, "no position was stated")
    try device.setPosition(beforeTurn(10))
    #expect(device.state.progress?.step == 0)
    device.close()
  }
}
