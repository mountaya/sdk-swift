import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersPanelHeading")
struct LayersPanelHeadingTests {
  @Test("two headings are equal where they read the same word, by its scalars")
  func equality() {
    #expect(
      LayersPanelHeading(word: "layers.terrain") == LayersPanelHeading(word: "layers.terrain"))
    #expect(LayersPanelHeading(word: "layers.terrain") != LayersPanelHeading(word: "layers.time"))
    #expect(
      LayersPanelHeading(word: "\u{C9}t\u{E9}") != LayersPanelHeading(word: "E\u{301}te\u{301}"))
  }
}
