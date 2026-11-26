import Testing

@testable import MountayaGeo

@Suite("profilePolyline")
struct ProfilePolylineTests {
  private let domain = ElevationDomain(min: 1_000, max: 1_500)
  private let climb = ElevationSeries(
    points: samplesEvery100Meters(
      1_000, 1_050, 1_100, 1_150, 1_200, 1_250, 1_300, 1_350, 1_400, 1_450, 1_500),
    totalDistance: 1_000, minElevation: 1_000, maxElevation: 1_500)

  @Test("a ridge on two equal legs is drawn floor, middle and top")
  func ridge() {
    let ridge = ElevationSeries(
      points: samples((0, 2_400), (500, 2_500), (1_000, 2_600)), totalDistance: 1_000,
      minElevation: 2_400, maxElevation: 2_600)
    #expect(
      profilePolyline(ridge, domain: ElevationDomain(min: 2_400, max: 2_600))
        == [PlotPoint(x: 0, y: 96), PlotPoint(x: 50, y: 51), PlotPoint(x: 100, y: 6)])
  }

  @Test("a window draws one sample beyond each end, unclamped")
  func window() {
    #expect(
      profilePolyline(climb, domain: domain, window: ProfileRange(from: 250, to: 450)).map(\.x)
        == [-25, 25, 75, 125])
    #expect(
      profilePolyline(climb, domain: domain, window: ProfileRange(from: 300, to: 500)).map(\.x)
        == [-50, 0, 50, 100, 150])
    #expect(
      profilePolyline(climb, domain: domain, window: ProfileRange(from: 1_000, to: 800)).map(\.x)
        == [-50, 0, 50, 100])
  }

  @Test("two lines meeting at one distance are joined there")
  func linesMeet() {
    let joined = ElevationSeries(
      points: samples((0, 1_000), (500, 1_200), (500, 1_250), (1_000, 1_300)),
      totalDistance: 1_000, minElevation: 1_000, maxElevation: 1_300)
    #expect(
      profilePolyline(joined, domain: domain)
        == [
          PlotPoint(x: 0, y: 96), PlotPoint(x: 50, y: 60), PlotPoint(x: 50, y: 51),
          PlotPoint(x: 100, y: 42),
        ])
  }

  @Test("a window the samples do not reach, and a series with no sample, draw nothing")
  func nothing() {
    let short = ElevationSeries(
      points: samples((0, 1_000), (250, 1_250), (500, 1_500)), totalDistance: 1_000,
      minElevation: 1_000, maxElevation: 1_500)
    #expect(
      profilePolyline(short, domain: domain, window: ProfileRange(from: 600, to: 800)).isEmpty)
    let empty = ElevationSeries(
      points: [], totalDistance: 1_000, minElevation: nil, maxElevation: nil)
    #expect(profilePolyline(empty, domain: domain).isEmpty)
  }

  @Test("a window before every sample draws the first two")
  func before() {
    let late = samples((500, 1_000), (600, 1_100), (700, 1_200))
    #expect(drawnSamples(late, window: ProfileRange(from: 0, to: 100)).map(\.index) == [0, 1])
    #expect(drawnSamples(late, window: nil).count == 3)
  }
}
