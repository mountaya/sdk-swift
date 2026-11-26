import Foundation
import Testing

@testable import MountayaGeo

@Suite("unitPatterns")
struct UnitPatternsTests {
  @Test("the table holds the seven languages the contract's Locales are keyed by")
  func languages() {
    #expect(unitPatternLanguages == ["de", "en", "es", "fr", "it", "ja", "zh"])
  }

  @Test("a language is read by its primary subtag, and any other writes English")
  func primarySubtag() {
    #expect(unitPatterns("fr") == unitPatterns("FR_ca"))
    #expect(unitPatterns("en") == unitPatterns("frr"))
    #expect(unitPatterns("en") == unitPatterns("ar-EG"))
    #expect(unitPatterns("en") == unitPatterns("not a tag"))
    #expect(unitPatterns("fr") != unitPatterns("en"))
  }

  /// A plain space is U+0020, a no-break space U+00A0 and a narrow one U+202F, each CLDR 48's.
  @Test("each language spaces its unit its own way")
  func spacing() {
    #expect(unitPatterns("en").kilometer == "{0}\u{20}km")
    #expect(unitPatterns("fr").kilometer == "{0}\u{202F}km")
    #expect(unitPatterns("en").celsius == "{0}°C")
    #expect(unitPatterns("fr").celsius == "{0}\u{202F}°C")
    #expect(unitPatterns("fr").minutePerMile == "{0}\u{A0}min/mi")
    #expect(unitPatterns("de").percent == "{0}\u{A0}%")
    #expect(unitPatterns("zh").kilometer == "{0}公里")
    #expect(unitPatterns("en").milePerHour == "{0} mph")
    #expect(unitPatterns("fr").milePerHour == "{0}\u{202F}mi/h")
  }

  @Test("every pattern holds the number once, and Spanish and Italian group from 10,000")
  func everyPattern() {
    for language in unitPatternLanguages {
      let row = unitPatterns(language)
      let patterns = [
        row.kilometer, row.mile, row.meter, row.foot, row.percent, row.kilometerPerHour,
        row.milePerHour, row.minutePerKilometer, row.minutePerMile, row.celsius, row.fahrenheit,
        row.hour, row.minute,
      ]
      for pattern in patterns {
        #expect(pattern.components(separatedBy: "{0}").count == 2, "\(language): `\(pattern)`")
      }
      #expect(
        row.minimumGroupingDigits == (["es", "it"].contains(language) ? 2 : 1), "\(language)")
    }
  }

  @Test("two rows are equal where every pattern is written with the same scalars")
  func equality() {
    #expect(unitPatterns("fr") == unitPatterns("fr"))
    #expect(unitPatterns("fr").hashValue == unitPatterns("fr").hashValue)
    #expect(unitPatterns("fr") != unitPatterns("en"))
    let composed = UnitPatterns(
      kilometer: "\u{E9}", mile: "", meter: "", foot: "", centimeter: "", inch: "", percent: "",
      kilometerPerHour: "",
      milePerHour: "", minutePerKilometer: "", minutePerMile: "", celsius: "", fahrenheit: "",
      hour: "", minute: "", minimumGroupingDigits: 1)
    let decomposed = UnitPatterns(
      kilometer: "e\u{301}", mile: "", meter: "", foot: "", centimeter: "", inch: "", percent: "",
      kilometerPerHour: "",
      milePerHour: "", minutePerKilometer: "", minutePerMile: "", celsius: "", fahrenheit: "",
      hour: "", minute: "", minimumGroupingDigits: 1)
    #expect(composed != decomposed)
  }
}
