import Testing

@testable import MountayaGeo

@Suite("SectionChipStat")
struct SectionChipStatTests {
  @Test("each figure is spelled as the contract spells it")
  func spelling() {
    #expect(SectionChipStat.allCases.map(\.rawValue) == ["distance", "ascent", "descent", "grade"])
  }
}
