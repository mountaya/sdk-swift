import Testing

@testable import MountayaGeo

@Suite("ZoomStep")
struct ZoomStepTests {
  @Test("each control is spelled as the contract spells it")
  func spellings() {
    #expect(ZoomStep.allCases.map(\.rawValue) == ["zoom-in", "zoom-out"])
  }
}
