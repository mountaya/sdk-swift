import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersPanelChoice")
struct LayersPanelChoiceTests {
  @Test("each choice is spelled as the contract spells it")
  func spellings() {
    #expect(
      LayersPanelChoice.allCases.map(\.rawValue) == ["terrain", "overlay", "enrichment", "time"])
  }
}
