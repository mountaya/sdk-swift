import Testing

@testable import MountayaGeo

@Suite("NavigationRouteSource")
@MainActor
struct NavigationRouteSourceTests {
  /// Asked keeps every request a source is handed, off the main actor, where a source runs.
  private actor Asked {
    var requests: [[[Double]]] = []

    func record(_ request: [[Double]]) {
      requests.append(request)
    }
  }

  @Test("a source is the host's async call, handed the request as the host made it")
  func handedTheRequest() async throws {
    let asked = Asked()
    let source: NavigationRouteSource<[[Double]]> = { waypoints in
      await asked.record(waypoints)
      return NavigationRoute(line: waypoints)
    }
    let engine = RouteFollowingEngine(route: source)
    let states = engine.subscribe()

    engine.start([[6.8652, 45.9237], [6.9271, 45.9682]])
    for await state in states where state.status == .navigating { break }

    #expect(await asked.requests == [[[6.8652, 45.9237], [6.9271, 45.9682]]])
    #expect(engine.state.route?.line == [[6.8652, 45.9237], [6.9271, 45.9682]])
    engine.close()
  }
}
