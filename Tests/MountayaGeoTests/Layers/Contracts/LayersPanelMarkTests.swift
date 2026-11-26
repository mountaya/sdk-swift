import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersPanelMark")
struct LayersPanelMarkTests {
  @Test("each mark is spelled as the contract spells it")
  func spellings() {
    #expect(LayersPanelMark.allCases.map(\.rawValue) == ["lock", "tick"])
  }
}
