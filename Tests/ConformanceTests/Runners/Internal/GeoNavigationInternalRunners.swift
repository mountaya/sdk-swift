import GateSupport
import MountayaClient

@testable import MountayaGeo

extension InternalRunners {
  /// navigationOffRoute answers whether a traveller is off the route. A case with `meters` holds
  /// the threshold to a distance already measured; one with a `line` and a `position` measures the
  /// traveller to the route as a corridor is measured. The fixture's threshold is held to
  /// `offRouteMeters`.
  static let navigationOffRoute = Runner(id: "geo.navigation.off-route", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(["offRouteMeters": offRouteMeters])
    let input = fixtureCase.input
    if let meters = try input.optionalNumber(at: "meters") {
      return .value(.bool(isOffRoute(meters)))
    }
    let line = GeoJSONLineString(coordinates: try input.positions(at: "line"))
    return .value(.bool(isOffRouteAt(try input.numbers(at: "position"), lines: [line])))
  }

  /// navigationStatus answers the status a navigation reports after each of the case's `events`,
  /// from the one every navigation starts in. The fixture's two closed sets are held to
  /// `NavigationStatus`'s and `NavigationEvent`'s cases in order, its initial status to the status
  /// of `NavigationState.idle`, and its table, cell by cell, to `navigationStatusAfter(_:on:)`.
  static let navigationStatus = Runner(id: "geo.navigation.status", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "events": GeoFixtures.texts(NavigationEvent.allCases.map(\.id)),
        "initial": .string(NavigationState.idle.status.id),
        "statuses": GeoFixtures.texts(NavigationStatus.allCases.map(\.id)),
        "transitions": .object(
          NavigationStatus.allCases.map { status in
            OrderedJSON.Member(
              key: status.id,
              value: .object(
                NavigationEvent.allCases.map { event in
                  OrderedJSON.Member(
                    key: event.id, value: .string(navigationStatusAfter(status, on: event).id))
                }))
          }),
      ])
    var status = NavigationState.idle.status
    var after: [OrderedJSON] = []
    for id in try GeoFixtures.textList(fixtureCase.input, at: "events") {
      guard let event = NavigationEvent.allCases.first(where: { $0.id == id }) else {
        throw FixtureError(description: "`\(id)` is no event")
      }
      status = navigationStatusAfter(status, on: event)
      after.append(.string(status.id))
    }
    return .value(.array(after))
  }

  /// navigationRouteRequest answers which of the case's requests leave, and which answers are
  /// acted on, as its `events` happen in order. A request is named by the case; an `answer` or a
  /// `fail` names the request it answers, which the runner reads as the ticket that request last
  /// left under, and a route and a failure are one answer to the rule, told apart only in what is
  /// delivered.
  static let navigationRouteRequest = Runner(
    id: "geo.navigation.route-request", table: .internal
  ) { _, fixtureCase in
    var requests = RouteRequests<String>.atRest
    var tickets: [String: Int] = [:]
    var sent: [OrderedJSON] = []
    var delivered: [OrderedJSON] = []
    func leave(_ send: RouteRequests<String>.Send?) {
      guard let send else { return }
      tickets[send.request] = send.ticket
      sent.append(.string(send.request))
    }
    for event in try fixtureCase.input.array(at: "events") {
      switch try event.string(at: "event") {
      case "request":
        let outcome = routeRequestsAfter(requests, on: .made(try event.string(at: "request")))
        requests = outcome.state
        leave(outcome.send)
      case let kind where kind == "answer" || kind == "fail":
        let request = try event.string(at: "request")
        guard let ticket = tickets[request] else {
          throw FixtureError(description: "`\(request)` is answered and was never sent")
        }
        let outcome = routeRequestsAfter(requests, on: .answered(ticket: ticket))
        requests = outcome.state
        leave(outcome.send)
        if outcome.deliver {
          delivered.append(
            .object([
              OrderedJSON.Member(
                key: "answer", value: .string(kind == "answer" ? "route" : "failure")),
              OrderedJSON.Member(key: "request", value: .string(request)),
            ]))
        }
      case "cancel":
        requests = routeRequestsAfter(requests, on: .cancelled).state
      case let other:
        throw FixtureError(description: "`\(other)` is no event")
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "delivered", value: .array(delivered)),
        OrderedJSON.Member(key: "sent", value: .array(sent)),
      ]))
  }

  /// navigationPrompts answers the prompts a route's maneuvers are announced with, `plan`, or the
  /// id of the one due at the case's `progress`, `due`. The route is built through
  /// `followedRouteOf(_:)` from the case's `line` and `steps`, as `geo.navigation.progress` builds
  /// it, and laid out by `guidancePlanOf(_:)`, the plan `DeviceNavigationEngine` speaks from; the
  /// due prompt is `duePrompt(_:progress:)`'s, a null `progress` read as no position. The
  /// fixture's trigger and slack are held to `promptMeters` and `promptSlackMeters`.
  static let navigationPrompts = Runner(id: "geo.navigation.prompts", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "promptMeters": promptMeters, "promptSlackMeters": promptSlackMeters,
    ])
    let input = fixtureCase.input
    guard
      let route = followedRouteOf(
        NavigationRoute(
          line: try input.positions(at: "line"), steps: try NavigationFixtures.steps(input))),
      let plan = guidancePlanOf(route)
    else {
      throw FixtureError(description: "the case's line names no place")
    }
    switch try input.string(at: "ask") {
    case "plan":
      return .value(
        .array(
          plan.steps.map { step in
            .object([
              OrderedJSON.Member(key: "length", value: .number(step.meters)),
              OrderedJSON.Member(
                key: "prompts",
                value: .array(
                  step.prompts.map { prompt in
                    .object([
                      OrderedJSON.Member(key: "id", value: .number(Double(prompt.id))),
                      OrderedJSON.Member(key: "instruction", value: written(prompt.instruction)),
                      OrderedJSON.Member(key: "trigger", value: .number(prompt.meters)),
                    ])
                  })),
            ])
          }))
    case "due":
      let progress = try navigationProgress(input["progress"])
      return .value(duePrompt(plan, progress: progress).map { .number(Double($0.id)) } ?? .null)
    case let other:
      throw FixtureError(description: "no question is called `\(other)`")
    }
  }

  /// written is an instruction as `geo.navigation.instruction-keys` writes one: its key, and each
  /// argument its key takes, by name.
  private static func written(_ instruction: NavigationInstruction) -> OrderedJSON {
    .object([
      OrderedJSON.Member(
        key: "arguments",
        value: .object(
          instruction.key.arguments.map { argument in
            switch argument {
            case .exit:
              OrderedJSON.Member(
                key: argument.id, value: instruction.exit.map { .number(Double($0)) } ?? .null)
            case .name:
              OrderedJSON.Member(
                key: argument.id, value: instruction.name.map { .string($0) } ?? .null)
            }
          })),
      OrderedJSON.Member(key: "key", value: .string(instruction.key.id)),
    ])
  }

  /// navigationProgress reads a progress as `geo.navigation.progress` writes one, or nil for null.
  private static func navigationProgress(_ written: OrderedJSON?) throws(FixtureError)
    -> NavigationProgress?
  {
    guard let written, !written.isNull else { return nil }
    func remainder(_ key: String) throws(FixtureError) -> NavigationRemainder {
      guard let value = written[key] else {
        throw FixtureError(description: "a progress names no `\(key)`")
      }
      return NavigationRemainder(
        distance: try value.number(at: "distance"),
        duration: try value.optionalNumber(at: "duration"))
    }
    return NavigationProgress(
      along: try written.number(at: "along"), step: try written.integer(at: "step"),
      next: try written.optionalInteger(at: "next"), toManeuver: try remainder("toManeuver"),
      toArrival: try remainder("toArrival"))
  }

  /// navigationEngineWalk plays the case's script over one `ScriptedNavigationEngine`, whose route
  /// requests the script answers with the case's `routes`, by the name each was asked under, and
  /// answers the requests it sent and the state it holds once each step has settled: each command
  /// has its effect before it returns, so the state read is the one it committed last.
  ///
  /// A position the engine refuses, one that names no place, throws `PositionError`, and the state
  /// read after it states `refused`. A case stating `failures` reads each state's `failure` too, the
  /// kind of the error the engine holds: `route-failed`, `empty-route`, or null for none.
  static let navigationEngineWalk = Runner(id: "geo.navigation.engine-walk", table: .internal) {
    _, fixtureCase in
    let input = fixtureCase.input
    let readsFailures = try input.flag(at: "failures")
    var routes: [String: NavigationRoute] = [:]
    for member in input["routes"]?.members ?? [] {
      routes[member.key] = NavigationRoute(
        line: try member.value.positions(at: "line"),
        steps: try NavigationFixtures.steps(member.value),
        duration: try member.value.optionalNumber(at: "duration"))
    }
    let steps = try input.array(at: "steps")
    let known = routes
    return try await MainActor.run { () throws -> RunnerOutcome in
      let engine = ScriptedNavigationEngine<String>()
      defer { engine.close() }
      var states: [OrderedJSON] = []
      for step in steps {
        var refused = false
        switch try step.string(at: "step") {
        case "start":
          engine.start(try step.string(at: "request"))
        case "reroute":
          engine.reroute(try step.string(at: "request"))
        case "answer":
          let name = try step.string(at: "request")
          guard let route = known[name] else {
            throw FixtureError(description: "the case holds no route `\(name)`")
          }
          try sentRequest(name, of: engine).answer(route)
        case "fail":
          try sentRequest(try step.string(at: "request"), of: engine).fail(RouteRefused())
        case "position":
          let position = try step.numbers(at: "position")
          do {
            try engine.setPosition(position)
          } catch {
            refused = true
          }
        case "stop":
          engine.stop()
        case let other:
          throw FixtureError(description: "`\(other)` is no step")
        }
        var state: [OrderedJSON.Member] = []
        if readsFailures {
          state.append(OrderedJSON.Member(key: "failure", value: failure(engine.state.error)))
        }
        state.append(OrderedJSON.Member(key: "progress", value: written(engine.state.progress)))
        if refused {
          state.append(OrderedJSON.Member(key: "refused", value: .bool(true)))
        }
        state.append(OrderedJSON.Member(key: "status", value: .string(engine.state.status.id)))
        states.append(.object(state))
      }
      return .value(
        .object([
          OrderedJSON.Member(key: "sent", value: .array(engine.sent.map { .string($0.request) })),
          OrderedJSON.Member(key: "states", value: .array(states)),
        ]))
    }
  }

  /// RouteRefused is the failure a route source answers a request the script fails with.
  struct RouteRefused: Error {}

  /// failure is the kind of the error an engine holds as the fixture names it, or null for none.
  private static func failure(_ error: NavigationError?) -> OrderedJSON {
    guard let error else { return .null }
    switch error.kind {
    case .routeFailed: return .string("route-failed")
    case .emptyRoute: return .string("empty-route")
    }
  }

  /// sentRequest is the last request the engine sent under `name`.
  @MainActor
  private static func sentRequest(
    _ name: String, of engine: ScriptedNavigationEngine<String>
  ) throws(FixtureError) -> ScriptedRouteRequest<String> {
    guard let request = engine.sent.last(where: { $0.request == name }) else {
      throw FixtureError(description: "the engine sent no request `\(name)`")
    }
    return request
  }

  /// written is a progress as `geo.navigation.progress` writes one, or null for none.
  private static func written(_ progress: NavigationProgress?) -> OrderedJSON {
    guard let progress else { return .null }
    func remainder(_ remainder: NavigationRemainder) -> OrderedJSON {
      .object([
        OrderedJSON.Member(key: "distance", value: .number(remainder.distance)),
        OrderedJSON.Member(key: "duration", value: NavigationFixtures.number(remainder.duration)),
      ])
    }
    return .object([
      OrderedJSON.Member(key: "along", value: .number(progress.along)),
      OrderedJSON.Member(
        key: "next", value: NavigationFixtures.number(progress.next.map(Double.init))),
      OrderedJSON.Member(key: "step", value: .number(Double(progress.step))),
      OrderedJSON.Member(key: "toArrival", value: remainder(progress.toArrival)),
      OrderedJSON.Member(key: "toManeuver", value: remainder(progress.toManeuver)),
    ])
  }
}
