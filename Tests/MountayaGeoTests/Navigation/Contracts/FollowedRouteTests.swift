import Testing

@testable import MountayaGeo

@Suite("FollowedRoute")
struct FollowedRouteTests {
  private let line: [[Double]] = [[0, 0], [0.01, 0]]

  private func followed(_ route: NavigationRoute) throws -> FollowedRoute {
    try #require(followedRouteOf(route))
  }

  @Test("two followed routes are equal by what they hold, and hash alike")
  func equality() throws {
    let route = try followed(NavigationRoute(line: line, duration: 600))

    #expect(route == (try followed(NavigationRoute(line: [[0, 0], [0.01, 0]], duration: 600))))
    #expect(
      route.hashValue
        == (try followed(NavigationRoute(line: [[0, 0], [0.01, 0]], duration: 600))).hashValue)
    #expect(route != (try followed(NavigationRoute(line: line, duration: 601))))
    #expect(route != (try followed(NavigationRoute(line: line.reversed(), duration: 600))))
    #expect(
      FollowedRoute(line: [[.nan, 0]], steps: []) == FollowedRoute(line: [[.nan, 0]], steps: []))
  }

  /// Measured once, when followed, so a position read along it never measures the line again.
  @Test("a followed route is measured once, as every walk of a line measures it")
  func measuredOnce() {
    let route = FollowedRoute(line: [[0, 0], [.nan, 1], [0.01, 0]], steps: [])

    #expect(route.measured == cumulativeMeters(route.line))
    #expect(route.measured[0] == route.measured[1])
  }

  /// Flattened once, when followed, so a position read along it walks numbers, not arrays.
  @Test("a followed route's vertices that name a place are flattened once, each with its measure")
  func placed() {
    let route = FollowedRoute(
      line: [[.nan, 1], [0, 0, 1_200], [5], [0.01, 0], [0.01, .infinity], [0.02, 0.01]], steps: [])

    #expect(route.placed.indices == [1, 3, 5])
    #expect(route.placed.longitudes == [0, 0.01, 0.02])
    #expect(route.placed.latitudes == [0, 0, 0.01])
    #expect(route.placed.meters == [1, 3, 5].map { route.measured[$0] })
    #expect(route.placed.meters == cumulativeMeters([[0, 0], [0.01, 0], [0.02, 0.01]]))
    #expect(FollowedRoute(line: [[.nan, .nan]], steps: []).placed.indices.isEmpty)
  }

  /// A copy shares the route's storage, so a state holding it compares no vertex. A route whose
  /// only vertex is NaN equals its copy, which an element-by-element IEEE comparison would not.
  @Test("a copy is the same route, compared by its storage first")
  func copies() {
    let route = FollowedRoute(line: [[.nan, .nan]], steps: [])
    let copy = route

    #expect(copy == route)
    #expect(copy.line.count == 1)
  }
}
