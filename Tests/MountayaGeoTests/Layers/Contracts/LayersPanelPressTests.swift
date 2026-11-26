import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersPanelPress")
struct LayersPanelPressTests {
  @Test("two presses are equal where they are of one kind and hold the same")
  func equality() {
    #expect(
      LayersPanelPress.command(.overlay, slug: "slopes") == .command(.overlay, slug: "slopes"))
    #expect(
      LayersPanelPress.command(.overlay, slug: "slopes") != .command(.terrain, slug: "slopes"))
    #expect(LayersPanelPress.command(.overlay, slug: "slopes") != .locked("slopes"))
    #expect(LayersPanelPress.locked("slopes") == .locked("slopes"))
    #expect(LayersPanelPress.locked("\u{E9}") != .locked("e\u{301}"))
  }
}
