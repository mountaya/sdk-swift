import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ElementsScopeStatement")
struct ElementsScopeStatementTests {
  @Test("a statement states nothing until it is given a setting")
  func empty() {
    let statement = ElementsScopeStatement()

    #expect(statement.language == nil)
    #expect(statement.locale == nil)
    #expect(statement.words == nil)
    #expect(statement.controlGlyphs == nil)
    #expect(statement.markerGlyphs == nil)
  }

  @Test("two statements are equal where they state the same, a text by its scalars")
  func equality() {
    let words = WordOverrides.bySection(["controls": ["zoomIn": "Plus"]])
    let a = ElementsScopeStatement(language: .fr, locale: "fr-CH", words: words)
    let b = ElementsScopeStatement(language: "fr", locale: "fr-CH", words: words)

    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
    #expect(a != ElementsScopeStatement(language: .fr, locale: "fr-CH"))
    #expect(a != ElementsScopeStatement(language: .fr, locale: "fr-ch", words: words))
    #expect(
      ElementsScopeStatement(locale: "\u{E9}") != ElementsScopeStatement(locale: "e\u{301}"))
    #expect(
      ElementsScopeStatement(controlGlyphs: .control)
        != ElementsScopeStatement(markerGlyphs: .control))
  }
}
