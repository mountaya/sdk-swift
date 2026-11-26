import Testing

@testable import MountayaGeo

@Suite("StatStripStat")
struct StatStripStatTests {
  @Test("each figure is spelled as the contract spells it")
  func spelling() {
    #expect(
      StatStripStat.allCases.map(\.rawValue)
        == ["distance", "duration", "ascent", "descent", "elevation", "grade", "difficulty"])
  }
}
