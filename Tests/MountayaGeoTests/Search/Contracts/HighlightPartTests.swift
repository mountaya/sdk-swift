import Testing

@testable import MountayaGeo

@Suite("HighlightPart")
struct HighlightPartTests {
  @Test("two parts are equal where they hold the same run and match")
  func equality() {
    #expect(HighlightPart(text: "Mont", match: true) == HighlightPart(text: "Mont", match: true))
    #expect(HighlightPart(text: "Mont", match: true) != HighlightPart(text: "Mont", match: false))
    // A run is compared as it is written, never by canonical equivalence.
    #expect(
      HighlightPart(text: "\u{E9}", match: true) != HighlightPart(text: "e\u{301}", match: true))
  }
}
