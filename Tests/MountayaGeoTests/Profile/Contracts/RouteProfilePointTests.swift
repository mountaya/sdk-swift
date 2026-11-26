import Testing

@testable import MountayaGeo

@Suite("RouteProfilePoint")
struct RouteProfilePointTests {
  @Test("two samples are equal when they hold the same numbers, and hash alike")
  func equality() {
    #expect(
      RouteProfilePoint(distanceKm: 0.8, elevation: 1_000)
        == RouteProfilePoint(distanceKm: 0.8, elevation: 1_000))
    #expect(
      RouteProfilePoint(distanceKm: 0.8, elevation: 1_000).hashValue
        == RouteProfilePoint(distanceKm: 0.8, elevation: 1_000).hashValue)
    #expect(
      RouteProfilePoint(distanceKm: 0.8, elevation: 1_000)
        != RouteProfilePoint(distanceKm: 1_000, elevation: 0.8))
    #expect(
      String(describing: RouteProfilePoint(distanceKm: 0.8, elevation: 1_000))
        == "RouteProfilePoint(distanceKm: 0.8, elevation: 1000.0)")
  }
}
