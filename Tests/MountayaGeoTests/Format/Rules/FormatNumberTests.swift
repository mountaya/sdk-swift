import Testing

@testable import MountayaGeo

@Suite("formatNumber")
struct FormatNumberTests {
  @Test("a number is written in the locale's own separators")
  func separators() {
    #expect(formatNumber(1_531, locale: "en-US") == "1,531")
    #expect(formatNumber(24.3, locale: "fr-FR", maximumFractionDigits: 1) == "24,3")
    #expect(formatNumber(24.3, locale: "en_US", maximumFractionDigits: 1) == "24.3")
    #expect(formatNumber(1_531, locale: "ar-EG") == "\u{661}\u{66C}\u{665}\u{663}\u{661}")
    // A numbering system the tag names is the one written, on every host.
    #expect(formatNumber(1_531, locale: "en-US-u-nu-arab") == "\u{661}\u{66C}\u{665}\u{663}\u{661}")
    #expect(formatNumber(1_531, locale: "bn-BD-u-nu-beng") == "\u{9E7},\u{9EB}\u{9E9}\u{9E7}")
  }

  @Test("the value is rounded half away from zero on its decimal value before the platform sees it")
  func rounding() {
    #expect(formatNumber(0.85, locale: "en", maximumFractionDigits: 1) == "0.9")
    #expect(formatNumber(2.675, locale: "en", maximumFractionDigits: 2) == "2.68")
    #expect(formatNumber(-2.5, locale: "en", maximumFractionDigits: 0) == "-3")
    #expect(formatNumber(-0.3, locale: "en", maximumFractionDigits: 0) == "0")
  }

  @Test("three places are kept by default, and none that is not needed")
  func places() {
    #expect(formatNumber(1.23456, locale: "en") == "1.235")
    #expect(formatNumber(2, locale: "en") == "2")
    #expect(formatNumber(2.4, locale: "en", maximumFractionDigits: -1) == "2")
    #expect(formatNumber(1.25, locale: "en", maximumFractionDigits: 99) == "1.25")
  }

  @Test("a value that is no finite number is nothing, and a locale that is no tag is English")
  func nothing() {
    #expect(formatNumber(.nan, locale: "en") == "")
    #expect(formatNumber(.infinity, locale: "en") == "")
    #expect(formatNumber(1_531, locale: "not a tag") == "1,531")
  }
}
