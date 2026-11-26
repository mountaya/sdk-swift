import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ElementsScope")
struct ElementsScopeTests {
  @Test("the standard scope is English in the locale en, the elements' words and bundled sets")
  func standard() {
    let scope = ElementsScope.standard

    #expect(scope.language == .en)
    #expect(scope.locale == "en")
    #expect(sameJson(scope.words, WordBundle.elements.english))
    #expect(scope.controlGlyphs == .control)
    #expect(scope.markerGlyphs == .marker)
  }

  @Test("a word is read by its path, the English word standing where an override left no text")
  func word() {
    let french = scopeOf(.standard, stating: ElementsScopeStatement(language: .fr))
    let numbered = scopeOf(
      .standard, stating: ElementsScopeStatement(words: .bySection(["controls": ["zoomIn": 3]])))

    #expect(ElementsScope.standard.word("controls.zoomIn") == "Zoom in")
    #expect(french.word("controls.zoomIn") == "Zoom avant")
    #expect(
      ElementsScope.standard.word("tooltips.geolocate.deniedDescription")
        == "Location is blocked. Allow it in your settings.")
    #expect(
      french.word("tooltips.geolocate.deniedDescription")
        == "Localisation bloquée\u{00A0}: autorisez-la dans vos réglages.")
    #expect(numbered.word("controls.zoomIn") == "Zoom in")
    #expect(numbered.word("controls.zoomOut") == "Zoom out")
  }

  @Test("a path that names no text is drawn as itself")
  func missing() {
    let scope = ElementsScope.standard

    #expect(scope.word("controls.nothing") == "controls.nothing")
    #expect(scope.word("controls") == "controls")
    #expect(scope.word("search.resultCount") == "search.resultCount")
    #expect(scope.word("") == "")
    #expect(scope.word("controls..zoomIn") == "controls..zoomIn")
  }

  @Test("a path's text is the word it names, and none where no word is text")
  func text() {
    #expect(ElementsScope.standard.text(at: "amenities.water") == "Water")
    #expect(ElementsScope.standard.text(at: "amenities.sauna") == nil)
    #expect(ElementsScope.standard.text(at: "waypointCard.summary") == nil)
    #expect(ElementsScope.standard.word("amenities.sauna") == "amenities.sauna")
  }

  @Test("two scopes are equal where they hold the same, a text by its scalars")
  func equality() {
    let a = scopeOf(.standard, stating: ElementsScopeStatement(locale: "fr-CH"))
    let b = scopeOf(.standard, stating: ElementsScopeStatement(locale: "fr-CH"))
    let other = scopeOf(.standard, stating: ElementsScopeStatement(locale: "fr-BE"))

    #expect(a == b)
    #expect(a.hashValue == b.hashValue)
    #expect(a != other)
    #expect(a != ElementsScope.standard)
  }
}
