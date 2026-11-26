import Testing

@testable import MountayaGeo

@Suite("NavigationState")
struct NavigationStateTests {
  private let line: [[Double]] = [[0, 0], [0.01, 0]]

  @Test("a navigation starts idle, holding nothing")
  func idle() {
    let idle = NavigationState.idle

    #expect(idle.status == .idle)
    #expect(idle.route == nil)
    #expect(idle.progress == nil)
    #expect(idle.error == nil)
  }

  /// By what they hold, so a route landing equal to the one held, or a reading that did not move,
  /// is no change an engine reports.
  @Test("two states are equal where every member is, and hash alike")
  func equality() throws {
    let route = try #require(followedRouteOf(NavigationRoute(line: line, duration: 600)))
    let held = NavigationState(status: .navigating, route: route)

    #expect(
      held
        == NavigationState(
          status: .navigating, route: followedRouteOf(NavigationRoute(line: line, duration: 600))))
    #expect(held.hashValue == NavigationState(status: .navigating, route: route).hashValue)
    #expect(held != NavigationState(status: .offRoute, route: route))
    #expect(held != NavigationState(status: .navigating, route: route, error: .emptyRoute()))
    #expect(held != NavigationState(status: .navigating))
  }
}
