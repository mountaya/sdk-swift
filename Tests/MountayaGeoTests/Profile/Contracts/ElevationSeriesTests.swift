import Testing

@testable import MountayaGeo

@Suite("ElevationSeries")
struct ElevationSeriesTests {
  private let samples = [
    ElevationPoint(distance: 0, elevation: 1_035, lngLat: [6.8652, 45.9237], index: 0)
  ]

  @Test("a series has elevation exactly where it has a sample")
  func hasElevation() {
    #expect(
      ElevationSeries(points: samples, totalDistance: 0, minElevation: 1_035, maxElevation: 1_035)
        .hasElevation)
    #expect(
      !ElevationSeries(points: [], totalDistance: 7_117.5, minElevation: nil, maxElevation: nil)
        .hasElevation)
  }

  @Test("two series are equal when every sample and figure is, and hash alike")
  func equality() {
    let series = ElevationSeries(
      points: samples, totalDistance: 10, minElevation: 1_035, maxElevation: 1_035)
    let copy = ElevationSeries(
      points: Array(samples), totalDistance: 10, minElevation: 1_035, maxElevation: 1_035)
    #expect(series == copy)
    #expect(series.hashValue == copy.hashValue)
    #expect(
      series
        != ElevationSeries(
          points: samples, totalDistance: 10, minElevation: nil, maxElevation: 1_035))
    #expect(
      ElevationSeries(points: [], totalDistance: 0, minElevation: nil, maxElevation: nil)
        != ElevationSeries(points: [], totalDistance: -0.0, minElevation: nil, maxElevation: nil))
    #expect(
      String(
        describing: ElevationSeries(
          points: [], totalDistance: 0, minElevation: nil, maxElevation: nil))
        == "ElevationSeries(points: [], totalDistance: 0.0, minElevation: nil, maxElevation: nil)")
  }
}
