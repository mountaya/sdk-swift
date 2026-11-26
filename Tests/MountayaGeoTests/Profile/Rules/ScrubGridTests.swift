import Testing

@testable import MountayaGeo

@Suite("scrubGrid")
struct ScrubGridTests {
  @Test("a scrub reads 240 columns")
  func columns() {
    #expect(profileScrubColumns == 240)
    #expect(scrubGrid(samples((0, 1_000)), window: ProfileRange(from: 0, to: 10)).count == 240)
  }

  @Test("two samples split the columns at their midpoint")
  func split() {
    let grid = scrubGrid(
      samples((0, 1_000), (1_000, 1_100)), window: ProfileRange(from: 0, to: 1_000))
    #expect(grid[0..<120].allSatisfy { $0 == 0 })
    #expect(grid[120...].allSatisfy { $0 == 1 })
  }

  @Test("a window reads its own columns, and past the samples the nearest end")
  func window() {
    let points = samplesEvery100Meters(
      1_000, 1_010, 1_020, 1_030, 1_040, 1_050, 1_060, 1_070, 1_080, 1_090, 1_100)
    let grid = scrubGrid(points, window: ProfileRange(from: 300, to: 540))
    #expect(grid[0] == 3 && grid[49] == 3 && grid[50] == 4 && grid[149] == 4 && grid[150] == 5)
    let past = scrubGrid(
      samples((0, 1_000), (500, 1_100)), window: ProfileRange(from: 600, to: 1_000))
    #expect(past.allSatisfy { $0 == 1 })
  }

  @Test("with no sample a column resolves to none")
  func none() {
    #expect(scrubGrid([], window: ProfileRange(from: 0, to: 1_000)).allSatisfy { $0 == nil })
  }

  @Test("a column stands for the distance at its centre")
  func distance() {
    let window = ProfileRange(from: 0, to: 1_000)
    #expect(isClose(scrubDistance(column: 0, window: window), 2.0833333333333335, within: 1e-12))
    #expect(isClose(scrubDistance(column: 239, window: window), 997.9166666666666, within: 1e-12))
    #expect(scrubDistance(column: 0, window: ProfileRange(from: 0, to: 240)) == 0.5)
  }
}
