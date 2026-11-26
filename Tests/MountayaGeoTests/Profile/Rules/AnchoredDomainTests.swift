import Testing

@testable import MountayaGeo

@Suite("anchoredDomain")
struct AnchoredDomainTests {
  private let series = ElevationSeries(
    points: samples((0, 1_035), (1_000, 1_220), (2_000, 1_480), (3_000, 1_850)),
    totalDistance: 3_000, minElevation: 1_035, maxElevation: 1_850)

  @Test("the route frames the itinerary whatever the window")
  func route() {
    #expect(
      anchoredDomain(series, anchor: .route, window: ProfileRange(from: 0, to: 500))
        == ElevationDomain(min: 1_000, max: 1_850))
  }

  @Test("sea level moves the floor of the route's frame to zero, its ceiling kept")
  func seaLevel() {
    #expect(
      anchoredDomain(series, anchor: .seaLevel, window: ProfileRange(from: 0, to: 500))
        == ElevationDomain(min: 0, max: 1_850))
    let flat = ElevationSeries(points: [], totalDistance: 100, minElevation: nil, maxElevation: nil)
    #expect(anchoredDomain(flat, anchor: .seaLevel) == ElevationDomain(min: 0, max: 50))
  }

  @Test("the window frames the stretch it holds, and the route where none is given")
  func window() {
    #expect(
      anchoredDomain(series, anchor: .window, window: ProfileRange(from: 0, to: 1_000))
        == ElevationDomain(min: 1_030, max: 1_220))
    #expect(anchoredDomain(series, anchor: .window) == ElevationDomain(min: 1_000, max: 1_850))
  }
}
