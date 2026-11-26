import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatElevation")
struct FormatElevationTests {
  @Test("an elevation is whole meters or feet")
  func wholeUnits() {
    #expect(formatElevation(1_531, units: UnitPreferences(language: "en")) == "1,531 m")
    #expect(
      formatElevation(1_531, units: UnitPreferences(language: "en", length: .imperial))
        == "5,023 ft")
    #expect(
      formatElevation(1_531, units: UnitPreferences(language: "fr")) == "1\u{202F}531\u{202F}m")
    #expect(
      formatElevation(1_531, units: UnitPreferences(language: "fr", length: .imperial))
        == "5\u{202F}023\u{202F}pi")
  }

  @Test("an elevation that rounds to zero has no sign, and a missing one is nothing")
  func zeroAndMissing() {
    #expect(formatElevation(-0.4, units: UnitPreferences(language: "en")) == "0 m")
    #expect(formatElevation(-0.5, units: UnitPreferences(language: "en")) == "-1 m")
    #expect(formatElevation(nil, units: UnitPreferences(language: "en")) == "")
    #expect(formatElevation(-.infinity, units: UnitPreferences(language: "en")) == "")
  }
}
