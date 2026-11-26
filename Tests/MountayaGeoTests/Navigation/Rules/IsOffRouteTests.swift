import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("isOffRoute")
struct IsOffRouteTests {
  private let route = [GeoJSONLineString(coordinates: [[6.86, 45.85], [6.9, 45.85]])]

  @Test("the threshold is fifty meters for everyone")
  func threshold() {
    #expect(offRouteMeters == 50)
  }

  @Test("a traveller is on route at the threshold, and off past it")
  func atTheThreshold() {
    #expect(!isOffRoute(50))
    #expect(!isOffRoute(49.99))
    #expect(isOffRoute(50.01))
    #expect(!isOffRoute(0))
  }

  /// A distance that is no number is past no threshold; the corridor never answers one, since a
  /// position that names no place is infinitely far.
  @Test("a distance that is no number is past no threshold, and infinity is past every one")
  func noNumber() {
    #expect(!isOffRoute(.nan))
    #expect(isOffRoute(.infinity))
    #expect(isOffRouteAt([.nan, 45.85], lines: route))
  }

  @Test("a traveller is measured to the route as a corridor is")
  func asACorridor() {
    #expect(!isOffRouteAt([6.88, 45.85], lines: route))
    #expect(!isOffRouteAt([6.88, 45.85 + 49 / metersPerDegreeMeanSphere], lines: route))
    #expect(isOffRouteAt([6.88, 45.85 + 51 / metersPerDegreeMeanSphere], lines: route))
    #expect(
      !isOffRouteAt(
        [179.9999, 0],
        lines: [GeoJSONLineString(coordinates: [[-179.9998, -1], [-179.9998, 1]])]))
  }

  /// A route of one vertex has no segment to be near, and neither has a route of no line.
  @Test("a route with no segment is off everywhere")
  func noSegment() {
    #expect(
      isOffRouteAt([6.88, 45.85], lines: [GeoJSONLineString(coordinates: [[6.88, 45.85]])]))
    #expect(isOffRouteAt([6.88, 45.85], lines: []))
  }
}
