import Testing

@testable import MountayaGeo

@Suite("profileReadout")
struct ProfileReadoutRuleTests {
  private let series = ElevationSeries(
    points: samples((0, 1_000), (200, 1_020), (400, 1_040), (600, 1_030)), totalDistance: 600,
    minElevation: 1_000, maxElevation: 1_040)

  @Test("the default figures are where the cursor stands, then what it took to get there")
  func defaults() {
    #expect(defaultReadoutStats == [.distance, .elevation, .ascent, .descent])
    let readout = profileReadout(series, at: series.points[3])
    #expect(readout.cells.map(\.value) == [600, 1_030, 40, 10])
    #expect(isClose(readout.grade ?? .nan, -2.862405226111748, within: 1e-9))
    #expect(readout.stretch == nil)
  }

  @Test("the figures in the order asked, the climb read off the one scan")
  func ordered() {
    let readout = profileReadout(series, at: series.points[2], stats: [.descent, .distance])
    #expect(
      readout.cells == [
        ReadoutCell(stat: .descent, value: 0), ReadoutCell(stat: .distance, value: 400),
      ])
    let jitter = ElevationSeries(
      points: samples((0, 1_000), (50, 1_003), (100, 1_001), (150, 1_006)), totalDistance: 150,
      minElevation: 1_000, maxElevation: 1_006)
    #expect(
      profileReadout(jitter, at: jitter.points[3]).cells.map(\.value) == [150, 1_006, 6, 0])
  }

  @Test("the stretch it stands in, the later at a shared boundary, and none in a gap")
  func stretch() {
    let stretches = [
      ProfileClass(from: 0, to: 400, color: "#2f9e44", label: "Path"),
      ProfileClass(from: 400, to: 600, color: "#e8590c", label: "Trail"),
    ]
    #expect(
      profileReadout(series, at: series.points[2], stretches: stretches).stretch?.label == "Trail"
    )
    #expect(
      profileReadout(series, at: series.points[1], stretches: stretches).stretch?.label == "Path")
    let short = [ProfileClass(from: 0, to: 300, color: "#2f9e44", label: "Path")]
    #expect(profileReadout(series, at: series.points[3], stretches: short).stretch == nil)
  }

  @Test("one sample has no grade")
  func one() {
    let one = ElevationSeries(
      points: samples((0, 1_000)), totalDistance: 0, minElevation: 1_000, maxElevation: 1_000)
    let readout = profileReadout(one, at: one.points[0])
    #expect(readout.grade == nil && readout.cells.map(\.value) == [0, 1_000, 0, 0])
  }
}
