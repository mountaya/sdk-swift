import MountayaGeo
import Testing

@testable import MountayaNavigation

@Suite("InertLocationSource")
@MainActor
struct InertLocationSourceTests {
  @Test("an inert source states no position, whatever it is asked")
  func statesNothing() async throws {
    let source = InertLocationSource()
    var stated: [[Double]] = []
    let route = try #require(followedRouteOf(NavigationRoute(line: [[0, 0], [0.01, 0]])))

    source.start { stated.append($0) }
    source.follow(route)
    await Task.yield()
    source.stop()
    source.stop()

    #expect(stated.isEmpty)
  }
}
