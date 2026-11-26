import Testing

@testable import MountayaGeo

@Suite("OverlayKind")
struct OverlayKindTests {
  @Test("an overlay is classic or an enrichment")
  func kinds() {
    #expect(OverlayKind.allCases == [.classic, .enrichment])
  }
}
