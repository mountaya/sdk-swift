import Testing

@testable import MountayaGeo

@Suite("profileAreaPath")
struct ProfileAreaPathTests {
  @Test("the area closes the line against the bottom of the square")
  func closed() {
    let ridge = ElevationSeries(
      points: samples((0, 2_400), (500, 2_500), (1_000, 2_600)), totalDistance: 1_000,
      minElevation: 2_400, maxElevation: 2_600)
    #expect(
      profileAreaPath(ridge, domain: ElevationDomain(min: 2_400, max: 2_600))
        == [
          .move(PlotPoint(x: 0, y: 100)), .line(PlotPoint(x: 0, y: 96)),
          .line(PlotPoint(x: 50, y: 51)), .line(PlotPoint(x: 100, y: 6)),
          .line(PlotPoint(x: 100, y: 100)), .close,
        ])
  }

  @Test("one sample draws a degenerate area, and no sample none")
  func edges() {
    let one = ElevationSeries(
      points: samples((0, 1_250)), totalDistance: 1_000, minElevation: 1_250, maxElevation: 1_250)
    #expect(
      profileAreaPath(one, domain: ElevationDomain(min: 1_000, max: 1_500))
        == [
          .move(PlotPoint(x: 0, y: 100)), .line(PlotPoint(x: 0, y: 51)),
          .line(PlotPoint(x: 0, y: 100)), .close,
        ])
    let empty = ElevationSeries(
      points: [], totalDistance: 1_000, minElevation: nil, maxElevation: nil)
    #expect(profileAreaPath(empty, domain: emptyElevationDomain).isEmpty)
  }
}
