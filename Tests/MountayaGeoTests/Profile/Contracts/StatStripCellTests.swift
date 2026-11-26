import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("StatStripCell")
struct StatStripCellTests {
  @Test("a cell names its figure and its number, the difficulty none")
  func members() {
    #expect(StatStripCell.distance(24_300).stat == .distance)
    #expect(StatStripCell.grade(18.5).number == 18.5)
    #expect(StatStripCell.difficulty("T3").stat == .difficulty)
    #expect(StatStripCell.difficulty("T3").number == nil)
  }

  @Test("two cells are equal where they state one figure of one value")
  func equality() {
    #expect(StatStripCell.ascent(1_531) == .ascent(1_531))
    #expect(StatStripCell.ascent(1_531) != .descent(1_531))
    #expect(StatStripCell.ascent(0) != .ascent(-0.0))
    #expect(StatStripCell.difficulty("T3") == .difficulty("T3"))
    #expect(StatStripCell.difficulty("T3") != .difficulty("t3"))
    #expect(StatStripCell.elevation(1_850).hashValue == StatStripCell.elevation(1_850).hashValue)
  }
}
