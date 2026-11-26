import Testing

@testable import MountayaElements

@Suite("MarkerImage")
struct MarkerImageTests {
  @Test("two images are equal where the glyph and the colour are written with the same scalars")
  func equality() {
    #expect(
      MarkerImage(glyph: "hut", color: "#1c7ed6") == MarkerImage(glyph: "hut", color: "#1c7ed6"))
    #expect(
      MarkerImage(glyph: "hut", color: "#1C7ED6") != MarkerImage(glyph: "hut", color: "#1c7ed6"))
    #expect(
      MarkerImage(glyph: "e\u{301}", color: "#000000")
        != MarkerImage(glyph: "\u{e9}", color: "#000000"))
  }
}
