import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatMeasurement")
struct FormatMeasurementTests {
  @Test("the number is rounded on its decimal value, then set in the pattern")
  func rounded() {
    #expect(
      formatMeasurement(0.85, fractionDigits: 1, pattern: "{0} km", language: "en") == "0.9 km")
    #expect(
      formatMeasurement(2.796, fractionDigits: 1, pattern: "{0} mi/h", language: "fr") == "2,8 mi/h"
    )
    #expect(formatMeasurement(-0.4, fractionDigits: 0, pattern: "{0} m", language: "en") == "0 m")
  }

  /// CLDR groups no Spanish or Italian number under 10,000, and every other language of the table
  /// from 1,000; Geo decides, so a locale data vintage that groups Italian from 1,000 (the Linux
  /// toolchain at 6.2.3) writes the same.
  @Test("a number is grouped as its language groups it")
  func grouping() {
    #expect(
      formatMeasurement(1_531, fractionDigits: 0, pattern: "{0} m", language: "es") == "1531 m")
    #expect(
      formatMeasurement(15_310, fractionDigits: 0, pattern: "{0} m", language: "es") == "15.310 m")
    #expect(
      formatMeasurement(1_531, fractionDigits: 0, pattern: "{0} m", language: "it-IT") == "1531 m")
    #expect(
      formatMeasurement(1_531, fractionDigits: 0, pattern: "{0} m", language: "de") == "1.531 m")
    #expect(
      formatMeasurement(1_531, fractionDigits: 0, pattern: "{0} m", language: "en") == "1,531 m")
    #expect(formatMeasurement(999, fractionDigits: 0, pattern: "{0} m", language: "en") == "999 m")
  }

  @Test("a figure stated to a fixed place keeps its zero")
  func fixedPlace() {
    #expect(
      formatMeasurement(
        1, fractionDigits: 1, pattern: "{0} km", language: "en", minimumFractionDigits: 1)
        == "1.0 km")
    #expect(
      formatMeasurement(
        1.15, fractionDigits: 1, pattern: "{0} km", language: "en", minimumFractionDigits: 1)
        == "1.2 km")
    #expect(
      formatMeasurement(
        1, fractionDigits: 1, pattern: "{0}\u{202F}km", language: "fr", minimumFractionDigits: 1)
        == "1,0\u{202F}km")
  }

  @Test("only the imperial system is imperial")
  func imperial() {
    #expect(isImperial(.imperial))
    #expect(!isImperial(.metric))
    #expect(!isImperial(RestSchema.UnitLength(rawValue: "nautical")))
    #expect(numberPlaceholder == "{0}")
  }
}
