import Testing

@testable import MountayaGeo

@Suite("localeNumberText")
struct LocaleNumberTextTests {
  @Test("a number is written in the locale it names")
  func locale() {
    #expect(
      localeNumberText(1_531, languageTag: "en-US", fractionDigits: 0, grouping: true) == "1,531")
    #expect(
      localeNumberText(24.3, languageTag: "fr-FR", fractionDigits: 1, grouping: true) == "24,3")
    #expect(localeNumberText(-22, languageTag: "en", fractionDigits: 0, grouping: true) == "-22")
    #expect(
      localeNumberText(1_531, languageTag: "fr", fractionDigits: 0, grouping: true)
        == "1\u{202F}531")
  }

  @Test("grouping is asked")
  func grouping() {
    #expect(
      localeNumberText(1_531, languageTag: "en-US", fractionDigits: 0, grouping: false) == "1531")
  }

  @Test("no fraction digit is written past the ones asked, or where none is needed")
  func fractionDigits() {
    #expect(localeNumberText(0.9, languageTag: "en", fractionDigits: 1, grouping: true) == "0.9")
    #expect(localeNumberText(100, languageTag: "en", fractionDigits: 1, grouping: true) == "100")
    #expect(localeNumberText(0, languageTag: "en", fractionDigits: 2, grouping: true) == "0")
    #expect(localeNumberText(2, languageTag: "en", fractionDigits: -4, grouping: true) == "2")
  }

  /// A figure stated to a fixed place keeps its zero, in the locale's own digits and mark.
  @Test("a minimum of fraction digits is always written")
  func minimumFractionDigits() {
    #expect(
      localeNumberText(
        1, languageTag: "en-US", fractionDigits: 1, grouping: false, minimumFractionDigits: 1)
        == "1.0")
    #expect(
      localeNumberText(
        1, languageTag: "fr-FR", fractionDigits: 1, grouping: false, minimumFractionDigits: 1)
        == "1,0")
    #expect(localeNumberText(1, languageTag: "en-US", fractionDigits: 1, grouping: false) == "1")
    #expect(
      localeNumberText(
        1, languageTag: "en-US", fractionDigits: 1, grouping: false, minimumFractionDigits: 5)
        == "1.0")
    #expect(
      localeNumberText(
        1, languageTag: "en-US", fractionDigits: 1, grouping: false, minimumFractionDigits: -2)
        == "1")
  }

  /// The format style writes an Indian grouping on every host; NumberFormatter on Linux does not.
  @Test("a locale's own grouping is written on every host")
  func indianGrouping() {
    #expect(
      localeNumberText(12_345_678, languageTag: "hi-IN", fractionDigits: 0, grouping: true)
        == "1,23,45,678")
  }
}
