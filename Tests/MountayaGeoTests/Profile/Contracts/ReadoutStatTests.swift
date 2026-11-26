import Testing

@testable import MountayaGeo

@Suite("ReadoutStat")
struct ReadoutStatTests {
  @Test("each figure is spelled as the contract spells it")
  func spelling() {
    #expect(ReadoutStat.allCases.map(\.rawValue) == ["distance", "elevation", "ascent", "descent"])
  }
}
