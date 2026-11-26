import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("wordOverridesOf")
struct WordOverridesOfTests {
  @Test("an override is keyed by section or by language")
  func shapes() {
    #expect(wordOverridesOf(["title": "Plan"]) == .bySection(["title": "Plan"]))
    #expect(
      wordOverridesOf(["de": ["title": "Karte"]]) == .byLanguage([.de: ["title": "Karte"]]))
    #expect(wordOverridesOf([:]) == .bySection([:]))
  }

  @Test("an override naming a language and a section together is refused")
  func refused() {
    #expect(wordOverridesOf(["fr": ["title": "Plan"], "title": "Chart"]) == nil)
  }

  /// Only the wire's own spelling of a language is a language key.
  @Test("a key is a language only as the wire spells it")
  func spelling() {
    #expect(
      wordOverridesOf(["FR": ["title": "Plan"]]) == .bySection(["FR": ["title": "Plan"]]))
    #expect(
      wordOverridesOf(["fr": ["title": "Plan"], "de": nil, "it": "word"])
        == .byLanguage([.fr: ["title": "Plan"]]))
  }
}
