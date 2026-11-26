import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatSnowfall")
struct FormatSnowfallTests {
  @Test("a depth of snow is whole centimeters in the metric system")
  func metric() {
    #expect(formatSnowfall(35, units: UnitPreferences(language: "en")) == "35 cm")
    #expect(formatSnowfall(35, units: UnitPreferences(language: "zh")) == "35厘米")
  }

  @Test("the imperial system reads inches to a decimal, its trailing zero dropped")
  func imperial() {
    let english = UnitPreferences(language: "en", length: .imperial)
    #expect(formatSnowfall(35, units: english) == "13.8 in")
    #expect(formatSnowfall(25.4, units: english) == "10 in")
    #expect(
      formatSnowfall(35, units: UnitPreferences(language: "fr", length: .imperial))
        == "13,8\u{202F}po")
  }

  @Test("a depth that is missing or no number is the empty string")
  func missing() {
    #expect(formatSnowfall(nil, units: UnitPreferences(language: "en")) == "")
    #expect(formatSnowfall(.nan, units: UnitPreferences(language: "en")) == "")
  }
}
