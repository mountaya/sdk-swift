import MountayaGeo
import Testing

@testable import MountayaNavigation

@Suite("LocationSource")
@MainActor
struct LocationSourceTests {
  /// Platform is a source that reads a platform, and so writes no `follow(_:)` of its own.
  @MainActor
  private final class Platform: LocationSource {
    var deliver: (@MainActor ([Double]) throws -> Void)?
    func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) { self.deliver = deliver }
    func stop() { deliver = nil }
  }

  @Test("a source that reads the platform is told of a route, and does nothing with it")
  func followIsOptional() throws {
    let source = Platform()
    let route = try #require(followedRouteOf(NavigationRoute(line: [[0, 0], [0.01, 0]])))
    var stated: [[Double]] = []

    source.start { stated.append($0) }
    source.follow(route)
    source.follow(nil)
    try source.deliver?([0.005, 0])

    #expect(stated == [[0.005, 0]])
  }

  @Test("a position the engine refuses is thrown back to the source that stated it")
  func refusalReachesTheSource() throws {
    let source = Platform()
    let engine = RouteFollowingEngine<String> { _ in NavigationRoute(line: [[0, 0]]) }
    source.start { position in try engine.setPosition(position) }

    #expect(throws: PositionError.self) { try source.deliver?([.nan, 0]) }
    engine.close()
  }
}
