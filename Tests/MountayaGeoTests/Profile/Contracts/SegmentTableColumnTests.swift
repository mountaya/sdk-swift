import Testing

@testable import MountayaGeo

@Suite("SegmentTableColumn")
struct SegmentTableColumnTests {
  @Test("each column is spelled as the contract spells it")
  func spelling() {
    #expect(
      SegmentTableColumn.allCases.map(\.rawValue)
        == ["segment", "profile", "distance", "elevation", "altitude", "duration", "difficulty"])
  }
}
