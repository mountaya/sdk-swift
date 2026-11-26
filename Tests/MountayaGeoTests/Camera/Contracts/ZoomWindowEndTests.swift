import Testing

@testable import MountayaGeo

@Suite("ZoomWindowEnd")
struct ZoomWindowEndTests {
  @Test("each end is spelled as the contract spells it")
  func spellings() {
    #expect(ZoomWindowEnd.allCases.map(\.rawValue) == ["none", "floor", "ceiling", "both"])
  }
}
