import Testing

@testable import MountayaGeo

@Suite("ReadoutCell")
struct ReadoutCellTests {
  @Test("two cells are equal where they state one figure of the same number")
  func equality() {
    #expect(ReadoutCell(stat: .ascent, value: 40) == ReadoutCell(stat: .ascent, value: 40))
    #expect(ReadoutCell(stat: .ascent, value: 40) != ReadoutCell(stat: .descent, value: 40))
    #expect(ReadoutCell(stat: .descent, value: 0) != ReadoutCell(stat: .descent, value: -0.0))
    #expect(
      ReadoutCell(stat: .distance, value: 400).hashValue
        == ReadoutCell(stat: .distance, value: 400).hashValue)
  }
}
