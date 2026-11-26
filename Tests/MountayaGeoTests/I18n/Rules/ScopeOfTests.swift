import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("scopeOf")
struct ScopeOfTests {
  /// french is French in the locale `fr-CH`, its zoom-in word written `Plus`.
  private static let french = scopeOf(
    .standard,
    stating: ElementsScopeStatement(
      language: .fr, locale: "fr-CH",
      words: .bySection(["controls": ["zoomIn": "Plus"]])))

  /// zoom reads a scope's two zoom words.
  private static func zoom(_ scope: ElementsScope) -> [String] {
    [scope.word("controls.zoomIn"), scope.word("controls.zoomOut")]
  }

  /// licensed is a set of the host's own, named `name`.
  private static func licensed(_ name: String) throws -> GlyphSet {
    try #require(GlyphSet(name: name, paint: .stroke, markup: ["zoom-in": #"<path d="M0 0"/>"#]))
  }

  @Test("a scope stating nothing takes every setting from the scope around it")
  func nothing() {
    let scope = scopeOf(Self.french, stating: ElementsScopeStatement())

    #expect(scope == Self.french)
    #expect(Self.zoom(scope) == ["Plus", "Zoom arrière"])
  }

  @Test("a scope stating another language resolves its words afresh, its locale following")
  func anotherLanguage() {
    let scope = scopeOf(Self.french, stating: ElementsScopeStatement(language: .en))

    #expect(scope.language == .en)
    #expect(scope.locale == "en")
    #expect(Self.zoom(scope) == ["Zoom in", "Zoom out"])
  }

  @Test("a scope restating the language around it keeps its words and its locale")
  func sameLanguage() {
    let scope = scopeOf(Self.french, stating: ElementsScopeStatement(language: "fr"))

    #expect(scope.locale == "fr-CH")
    #expect(Self.zoom(scope) == ["Plus", "Zoom arrière"])
  }

  @Test("a scope stating words resolves them from its language's base, its locale kept")
  func words() {
    let scope = scopeOf(
      Self.french,
      stating: ElementsScopeStatement(words: .bySection(["controls": ["zoomOut": "Moins"]])))

    #expect(scope.language == .fr)
    #expect(scope.locale == "fr-CH")
    #expect(Self.zoom(scope) == ["Zoom avant", "Moins"])
  }

  @Test("a stated locale stands beside a stated language, and alone keeps language and words")
  func locales() {
    let english = scopeOf(
      Self.french, stating: ElementsScopeStatement(language: .en, locale: "en-GB"))
    let belgian = scopeOf(Self.french, stating: ElementsScopeStatement(locale: "fr-BE"))

    #expect(english.locale == "en-GB")
    #expect(Self.zoom(english) == ["Zoom in", "Zoom out"])
    #expect(belgian.language == .fr)
    #expect(belgian.locale == "fr-BE")
    #expect(Self.zoom(belgian) == ["Plus", "Zoom arrière"])
  }

  @Test("words written for a language stay with the scope that wrote them")
  func wordsByLanguage() {
    let outer = scopeOf(
      .standard,
      stating: ElementsScopeStatement(words: .byLanguage([.fr: ["controls": ["zoomIn": "Plus"]]])))
    let inner = scopeOf(outer, stating: ElementsScopeStatement(language: .fr))
    let german = scopeOf(
      .standard,
      stating: ElementsScopeStatement(
        language: .de,
        words: .byLanguage([.de: ["controls": ["zoomIn": "Vergrößern"]]])))

    #expect(Self.zoom(outer) == ["Zoom in", "Zoom out"])
    #expect(inner.locale == "fr")
    #expect(Self.zoom(inner) == ["Zoom avant", "Zoom arrière"])
    #expect(german.locale == "de")
    #expect(Self.zoom(german) == ["Vergrößern", "Zoom out"])
  }

  @Test("a control set stated never stands in for the marker set, and each is inherited alone")
  func glyphs() throws {
    let controls = try Self.licensed("licensed-controls")
    let markers = try Self.licensed("licensed-markers")
    let stated = scopeOf(.standard, stating: ElementsScopeStatement(controlGlyphs: controls))
    let both = scopeOf(
      .standard, stating: ElementsScopeStatement(controlGlyphs: controls, markerGlyphs: markers))
    let inner = scopeOf(both, stating: ElementsScopeStatement(controlGlyphs: .control))

    #expect(stated.controlGlyphs == controls)
    #expect(stated.markerGlyphs == .marker)
    #expect(inner.controlGlyphs == .control)
    #expect(inner.markerGlyphs == markers)
  }

  @Test("three scopes deep, each takes what it does not state from the one around it")
  func threeDeep() {
    let first = scopeOf(.standard, stating: ElementsScopeStatement(language: .fr, locale: "fr-CH"))
    let second = scopeOf(
      first, stating: ElementsScopeStatement(words: .bySection(["controls": ["zoomIn": "Plus"]])))
    let third = scopeOf(second, stating: ElementsScopeStatement())

    #expect(third.language == .fr)
    #expect(third.locale == "fr-CH")
    #expect(Self.zoom(third) == ["Plus", "Zoom arrière"])
  }

  @Test("a language the elements carry no words for reads English, in its own locale")
  func untranslated() {
    let scope = scopeOf(.standard, stating: ElementsScopeStatement(language: .ja))

    #expect(scope.language == .ja)
    #expect(scope.locale == "ja")
    #expect(Self.zoom(scope) == ["Zoom in", "Zoom out"])
  }
}
