import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatAltitudeRange")
struct FormatAltitudeRangeTests {
  private func units(_ language: String, imperial: Bool = false) -> UnitPreferences {
    UnitPreferences(language: language, length: imperial ? .imperial : .metric)
  }

  @Test("a band is the language's range, the unit stated once")
  func ranges() {
    #expect(
      formatAltitudeRange(min: 1_035, max: 1_850, units: units("en")) == "1,035\u{2013}1,850 m")
    #expect(
      formatAltitudeRange(min: 1_035, max: 1_850, units: units("en", imperial: true))
        == "3,396\u{2013}6,070 ft")
    #expect(
      formatAltitudeRange(min: 1_035, max: 1_850, units: units("fr"))
        == "1\u{202F}035\u{2013}1\u{202F}850\u{202F}m")
    #expect(
      formatAltitudeRange(min: 1_034.6, max: 1_850.4, units: units("en")) == "1,035\u{2013}1,850 m")
    #expect(formatAltitudeRange(min: 1_035, max: 1_850, units: units("es")) == "1035-1850 m")
    #expect(
      formatAltitudeRange(min: 1_035, max: 1_850, units: units("ja")) == "1,035\u{FF5E}1,850 m")
    #expect(
      formatAltitudeRange(min: 1_850, max: 1_035, units: units("en")) == "1,850\u{2013}1,035 m")
  }

  @Test("two bounds written alike read approximately, a bound rounding to zero as zero")
  func approximately() {
    #expect(formatAltitudeRange(min: 999.6, max: 1_000.4, units: units("en")) == "~1,000 m")
    #expect(
      formatAltitudeRange(min: 999.6, max: 1_000.4, units: units("fr"))
        == "\u{2243}1\u{202F}000\u{202F}m")
    #expect(formatAltitudeRange(min: -0.4, max: 0.4, units: units("en")) == "~0 m")
    #expect(formatAltitudeRange(min: -430, max: -430, units: units("de")) == "\u{2248}-430 m")
  }

  @Test("a first bound below zero stands apart from the separator")
  func negative() {
    #expect(formatAltitudeRange(min: -3, max: 1_200, units: units("en")) == "-3 \u{2013} 1,200 m")
    #expect(formatAltitudeRange(min: 3, max: -1_200, units: units("en")) == "3\u{2013}-1,200 m")
  }

  @Test("either bound missing or no finite number gives nothing")
  func nothing() {
    #expect(formatAltitudeRange(min: nil, max: 1_850, units: units("en")) == "")
    #expect(formatAltitudeRange(min: 1_035, max: nil, units: units("en")) == "")
    #expect(formatAltitudeRange(min: 1_035, max: .nan, units: units("fr")) == "")
    #expect(formatAltitudeRange(min: .infinity, max: 1, units: units("en")) == "")
  }
}
