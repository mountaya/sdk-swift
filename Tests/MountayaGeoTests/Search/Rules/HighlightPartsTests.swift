import Testing

@testable import MountayaGeo

@Suite("highlightParts")
struct HighlightPartsTests {
  @Test("the title is split into matched and unmatched runs")
  func split() {
    #expect(
      highlightParts("Col du Galibier", query: "gali") == [
        HighlightPart(text: "Col du ", match: false), HighlightPart(text: "Gali", match: true),
        HighlightPart(text: "bier", match: false),
      ])
    #expect(
      highlightParts("\u{130}stanbul", query: "stan") == [
        HighlightPart(text: "\u{130}", match: false), HighlightPart(text: "stan", match: true),
        HighlightPart(text: "bul", match: false),
      ])
    #expect(
      highlightParts("Stra\u{DF}e", query: "stras") == [
        HighlightPart(text: "Stra\u{DF}", match: true), HighlightPart(text: "e", match: false),
      ])
  }

  @Test("a title with no match is one unmatched part")
  func noMatch() {
    #expect(
      highlightParts("Chamonix", query: "zermatt") == [
        HighlightPart(text: "Chamonix", match: false)
      ])
    #expect(
      highlightParts("Chamonix", query: "") == [HighlightPart(text: "Chamonix", match: false)])
    #expect(highlightParts("", query: "mont") == [HighlightPart(text: "", match: false)])
  }

  /// A part is cut on the scalars, so an accent written apart stays with its letter and nothing is
  /// recomposed: the parts joined are the title, scalar for scalar.
  @Test("the parts joined are the title, scalar for scalar")
  func scalarsKept() {
    let title = "Pre\u{301} Saint-Didier"
    let parts = highlightParts(title, query: "pre")
    #expect(
      parts == [
        HighlightPart(text: "Pre\u{301}", match: true),
        HighlightPart(text: " Saint-Didier", match: false),
      ])
    #expect(scalars(parts.map(\.text).joined()) == scalars(title))
  }
}
