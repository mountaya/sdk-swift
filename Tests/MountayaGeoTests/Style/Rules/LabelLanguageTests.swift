import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("labelLanguage")
struct LabelLanguageTests {
  @Test("a tag is read by its primary subtag, whatever its case")
  func primarySubtag() {
    #expect(labelLanguage("fr-CA") == .fr)
    #expect(labelLanguage("fr_CA") == .fr)
    #expect(labelLanguage("JA-JP") == .ja)
    #expect(labelLanguage("zh-Hant-TW") == .zh)
    #expect(labelLanguage("De") == .de)
    // A subtag ended by its hyphen is still the subtag.
    #expect(labelLanguage("fr-") == .fr)
  }

  @Test("a tag naming no label language, and no tag, label in English")
  func english() {
    for tag in ["frr", "pt-BR", "und-FR", "*", "", " fr", "fr CA", nil] as [String?] {
      #expect(labelLanguage(tag) == .en, "\(String(describing: tag))")
    }
  }

  /// Only the ASCII letters are folded: a dotted capital I folds to no ASCII `i`.
  @Test("a letter outside ASCII folds to no language")
  func asciiOnly() {
    #expect(labelLanguage("\u{130}t") == .en)
    #expect(labelLanguage("\u{FF26}\u{FF32}") == .en)
  }

  @Test("the languages are the seven Locales is keyed by")
  func languages() {
    #expect(labelLanguages.map(\.rawValue) == ["en", "fr", "es", "it", "de", "zh", "ja"])
  }
}
