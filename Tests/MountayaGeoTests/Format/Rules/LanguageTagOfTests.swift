import Testing

@testable import MountayaGeo

@Suite("languageTagOf")
struct LanguageTagOfTests {
  @Test("a language tag is handed on as it is written, an underscore read as a hyphen")
  func handedOn() {
    #expect(languageTagOf("fr-FR") == "fr-FR")
    #expect(languageTagOf("ar_EG") == "ar-EG")
    #expect(languageTagOf("zh_Hant_TW") == "zh-Hant-TW")
    #expect(languageTagOf("en-US-u-nu-arab") == "en-US-u-nu-arab")
  }

  @Test("a value that is no language tag reads as English")
  func fallback() {
    for locale in ["", " fr", "fr-", "e", "fr--FR", "français", "123", "fr-١٢"] {
      #expect(languageTagOf(locale) == "en", "`\(locale)`")
    }
    #expect(fallbackLanguage == "en")
  }

  @Test("the primary subtag is in lower case")
  func primary() {
    #expect(primaryLanguageOf("FR_ca") == "fr")
    #expect(primaryLanguageOf("frr") == "frr")
    #expect(primaryLanguageOf("not a tag") == "en")
  }
}
