import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatHumidity")
struct FormatHumidityTests {
  @Test("a humidity is a whole percent in the language's pattern, whatever the preferences")
  func wholePercent() {
    #expect(formatHumidity(54.6, units: UnitPreferences(language: "en")) == "55%")
    #expect(
      formatHumidity(54.6, units: UnitPreferences(language: "fr", length: .imperial))
        == "55\u{A0}%")
  }

  @Test("a humidity that rounds to zero has no sign, and none is the empty string")
  func zeroAndMissing() {
    #expect(formatHumidity(-0.4, units: UnitPreferences(language: "de")) == "0\u{A0}%")
    #expect(formatHumidity(nil, units: UnitPreferences(language: "en")) == "")
    #expect(formatHumidity(.infinity, units: UnitPreferences(language: "en")) == "")
  }
}
