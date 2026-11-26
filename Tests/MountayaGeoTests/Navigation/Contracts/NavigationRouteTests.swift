import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("NavigationRoute")
struct NavigationRouteTests {
  private let line: [[Double]] = [[0, 0], [0.01, 0]]

  @Test("a route states its line alone where it has no steps and no duration")
  func lineAlone() {
    let route = NavigationRoute(line: line)

    #expect(route.steps.isEmpty)
    #expect(route.duration == nil)
  }

  @Test("two routes are equal by what they hold, and hash alike")
  func equality() {
    let steps = [NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart)]

    #expect(
      NavigationRoute(line: line, steps: steps, duration: 600)
        == NavigationRoute(line: [[0, 0], [0.01, 0]], steps: steps, duration: 600))
    #expect(
      NavigationRoute(line: line, steps: steps, duration: 600).hashValue
        == NavigationRoute(line: [[0, 0], [0.01, 0]], steps: steps, duration: 600).hashValue)
    #expect(NavigationRoute(line: [[.nan, 0]]) == NavigationRoute(line: [[.nan, 0]]))
    #expect(NavigationRoute(line: [[0, 0]]) != NavigationRoute(line: [[-0.0, 0]]))
    #expect(NavigationRoute(line: line, duration: 600) != NavigationRoute(line: line))
    #expect(NavigationRoute(line: line, steps: steps) != NavigationRoute(line: line))
  }
}
