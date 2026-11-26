import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("resolveBundle")
struct ResolveBundleTests {
  private let english: [String: JSONValue] = [
    "controls": ["zoomIn": "Zoom in", "zoomOut": "Zoom out"], "title": "Map",
  ]
  private let french: [String: JSONValue] = [
    "controls": ["zoomIn": "Zoom avant", "zoomOut": "Zoom arri\u{E8}re"], "title": "Carte",
  ]
  private var bundle: WordBundle {
    WordBundle(english: english, translations: [.fr: french])
  }

  @Test("a language reads its translation, and one with none reads English")
  func base() {
    #expect(resolveBundle(bundle) == english)
    #expect(resolveBundle(bundle, language: .fr) == french)
    #expect(resolveBundle(bundle, language: .de) == english)
  }

  @Test("a translation handed over stands ahead of the bundle's own")
  func handedOver() {
    let plan: [String: JSONValue] = ["title": "Plan"]
    #expect(resolveBundle(bundle, language: .fr, handedOver: [.fr: plan]) == plan)
    #expect(
      resolveBundle(bundle, language: .it, handedOver: [.de: plan]) == english)
  }

  @Test("a partial layer folds over the base, and an override over the partial layer")
  func layers() throws {
    let partial = WordBundle(
      english: english, partial: [.de: ["controls": ["zoomIn": "Vergr\u{F6}\u{DF}ern"]]])
    #expect(
      resolveBundle(partial, language: .de)
        == (try jsonObject(
          #"{"controls": {"zoomIn": "Vergrößern", "zoomOut": "Zoom out"}, "title": "Map"}"#)))
    #expect(
      resolveBundle(
        WordBundle(english: english, translations: [.fr: french], partial: partial.partial),
        language: .fr) == french)
    let overrides = WordOverrides.byLanguage([
      .de: ["controls": ["zoomOut": "Verkleinern"], "title": "Karte"]
    ])
    #expect(
      resolveBundle(partial, language: .de, overrides: overrides)
        == (try jsonObject(
          #"{"controls": {"zoomIn": "Vergrößern", "zoomOut": "Verkleinern"}, "title": "Karte"}"#
        )))
  }

  @Test("an override by section is for the selected language, and one by language for its own")
  func overrides() throws {
    let bySection = WordOverrides.bySection(["controls": ["zoomIn": "Plus pr\u{E8}s"]])
    #expect(
      resolveBundle(bundle, language: .fr, overrides: bySection)
        == (try jsonObject(
          #"{"controls": {"zoomIn": "Plus près", "zoomOut": "Zoom arrière"}, "title": "Carte"}"#
        )))
    #expect(
      resolveBundle(
        bundle, language: .fr, overrides: .byLanguage([.en: ["title": "Chart"]]))
        == french)
  }

  /// A word written null is left out, and a list replaces as a word does.
  @Test("a null word is left out, and a list replaces")
  func nullAndLists() {
    let overrides = WordOverrides.bySection([
      "controls": ["zoomIn": nil], "title": "Plan", "steps": ["a"],
    ])
    let listed = WordBundle(english: [
      "controls": ["zoomIn": "Zoom in"], "title": "Map", "steps": ["x", "y"],
    ])
    #expect(
      resolveBundle(listed, overrides: overrides)
        == ["controls": ["zoomIn": "Zoom in"], "title": "Plan", "steps": ["a"]])
  }

  /// A key every JavaScript object has is folded on in no SDK.
  @Test("a key naming a prototype member is left out")
  func prototypeKeys() {
    let overrides = WordOverrides.bySection([
      "constructor": "x", "__proto__": ["title": "y"], "prototype": "z",
    ])
    #expect(resolveBundle(bundle, overrides: overrides) == english)
    #expect(
      resolveBundle(bundle, overrides: .bySection(["prototype": "z", "title": "Plan"]))
        == ["controls": ["zoomIn": "Zoom in", "zoomOut": "Zoom out"], "title": "Plan"])
  }

  /// Swift values have no identity, so "the tree beneath it" is a tree equal to it.
  @Test("an override that restates the words changes nothing")
  func restated() {
    #expect(
      resolveBundle(
        bundle, language: .fr, overrides: .bySection(["title": "Carte", "controls": [:]]))
        == french)
  }
}
