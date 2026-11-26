import Testing

@testable import MountayaGeo

@Suite("SectionChipCell")
struct SectionChipCellTests {
  @Test("two cells are equal where they state one figure of the same number")
  func equality() {
    #expect(SectionChipCell(stat: .grade, value: 4) == SectionChipCell(stat: .grade, value: 4))
    #expect(SectionChipCell(stat: .grade, value: 4) != SectionChipCell(stat: .ascent, value: 4))
    #expect(
      SectionChipCell(stat: .distance, value: 6_000).hashValue
        == SectionChipCell(stat: .distance, value: 6_000).hashValue)
  }
}
