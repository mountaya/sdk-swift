import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("statStripCells")
struct StatStripCellsTests {
  private let figures = ResolvedCharacteristics(
    distance: 24_300, duration: 32_400, ascent: 1_531, descent: 1_408, altitudeMin: 1_035,
    altitudeMax: 1_850, slopeMin: -15.2, slopeMax: 18.5, trailDifficultyMin: "T1",
    trailDifficultyMax: "T3")

  @Test("the default figures are the length, the climb, the loss and the highest point")
  func defaults() {
    #expect(defaultStatStripStats == [.distance, .ascent, .descent, .elevation])
    #expect(
      statStripCells(figures, cursor: nil)
        == [.distance(24_300), .ascent(1_531), .descent(1_408), .elevation(1_850)])
  }

  @Test("every figure in the order asked")
  func ordered() {
    #expect(
      statStripCells(figures, cursor: nil, stats: StatStripStat.allCases.reversed())
        == [
          .difficulty("T3"), .grade(18.5), .elevation(1_850), .descent(1_408), .ascent(1_531),
          .duration(32_400), .distance(24_300),
        ])
  }

  @Test("while a scrub stands the cursor states its distance, altitude and grade")
  func cursor() {
    let cursor = StatStripCursor(distance: 5_000, elevation: 1_400, grade: 6.2)
    #expect(
      statStripCells(figures, cursor: cursor, stats: [.grade, .elevation, .distance, .ascent])
        == [.grade(6.2), .elevation(1_400), .distance(5_000), .ascent(1_531)])
    let flat = StatStripCursor(distance: 5_000, elevation: 1_400, grade: nil)
    #expect(
      statStripCells(figures, cursor: flat, stats: [.grade, .distance]) == [.distance(5_000)])
  }

  @Test("a figure with no value takes no cell, and nothing asked states nothing")
  func missing() {
    let flat = ResolvedCharacteristics(distance: 24_300, slopeMin: -15.2)
    #expect(statStripCells(flat, cursor: nil) == [.distance(24_300)])
    #expect(statStripCells(flat, cursor: nil, stats: [.duration, .difficulty, .grade]).isEmpty)
    #expect(statStripCells(figures, cursor: nil, stats: []).isEmpty)
  }
}
