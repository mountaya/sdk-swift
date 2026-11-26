import Testing

@testable import MountayaGeo

@Suite("localeCollated")
struct LocaleCollatedTests {
  @Test("a text sorts by the reader's locale, whatever its case")
  func collated() {
    #expect(localeCollated("Food", before: "sauna", languageTag: "en"))
    #expect(localeCollated("sauna", before: "Water", languageTag: "en"))
    #expect(!localeCollated("Water", before: "Food", languageTag: "en"))
    #expect(localeCollated("Eau", before: "Nourriture", languageTag: "fr"))
    #expect(!localeCollated("Food", before: "Food", languageTag: "en"))
  }
}
