import Testing

@testable import MountayaGeo

@Suite("elevationAt")
struct ElevationAtTests {
  /// Two lines meet at 200 m: the earlier ends at 1,200 m of altitude and the later starts at
  /// 1,000.
  private let points = samples((0, 1_000), (100, 1_100), (200, 1_200), (200, 1_000), (300, 1_050))

  @Test("the curve is read on the line between the two samples either side")
  func between() {
    #expect(elevationAt(points, distance: 50) == 1_050)
    #expect(elevationAt(points, distance: 100) == 1_100)
    #expect(elevationAt(points, distance: 250) == 1_025)
  }

  @Test("beyond the samples the nearer end is read")
  func beyond() {
    #expect(elevationAt(points, distance: -10) == 1_000)
    #expect(elevationAt(points, distance: 900) == 1_050)
    #expect(elevationAt(points, distance: .nan) == nil)
    #expect(elevationAt([], distance: 0) == nil)
  }

  @Test("at the last sample's distance the last of the samples standing there is read")
  func lastDistance() {
    let ending = samples((0, 1_000), (100, 1_100), (100, 900))
    #expect(elevationAt(ending, distance: 100) == 900)
  }

  @Test("where two lines meet, a stretch ends on the earlier and starts on the later")
  func linesMeet() {
    #expect(elevationAt(points, distance: 200) == 1_200)
    #expect(startIndexAt(points, distance: 200) == 3)
    #expect(startElevationAt(points, distance: 200) == 1_000)
    #expect(startIndexAt(points, distance: 150) == -1)
    #expect(startElevationAt(points, distance: 150) == 1_150)
  }

  @Test("the first sample at or past a distance is found by halving")
  func halving() {
    #expect(firstIndexAtOrPast(points, distance: 0) == 0)
    #expect(firstIndexAtOrPast(points, distance: 150) == 2)
    #expect(firstIndexAtOrPast(points, distance: 200) == 2)
    #expect(firstIndexAtOrPast(points, distance: 301) == 5)
    #expect(firstIndexAtOrPast(points, distance: .nan) == 0)
  }
}
