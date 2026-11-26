import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatSpeed")
struct FormatSpeedTests {
  @Test("per time a rate is stated to one decimal")
  func perTime() {
    #expect(formatSpeed(4.5, units: UnitPreferences(language: "en")) == "4.5 km/h")
    #expect(
      formatSpeed(4.5, units: UnitPreferences(language: "en", length: .imperial))
        == "2.8 mph")
    #expect(
      formatSpeed(4.5, units: UnitPreferences(language: "fr", length: .imperial))
        == "2,8\u{202F}mi/h")
    #expect(formatSpeed(-0.04, units: UnitPreferences(language: "en")) == "0 km/h")
  }

  @Test("per distance a rate is the pace clock of its reciprocal")
  func perDistance() {
    #expect(
      formatSpeed(4.5, units: UnitPreferences(language: "en", pace: .perDistance))
        == "13:20 min/km")
    #expect(
      formatSpeed(
        4.5,
        units: UnitPreferences(
          language: "en", length: .imperial, pace: .perDistance))
        == "21:27 min/mi")
    #expect(
      formatSpeed(4.5, units: UnitPreferences(language: "fr", pace: .perDistance))
        == "13:20\u{A0}min/km")
    #expect(
      formatSpeed(1, units: UnitPreferences(language: "en", pace: .perDistance))
        == "60:00 min/km")
    // The clock is Latin in every language.
    #expect(
      formatSpeed(4.5, units: UnitPreferences(language: "ar-EG", pace: .perDistance))
        == "13:20 min/km")
  }

  @Test("a rate with no reciprocal, or no number, is nothing")
  func nothing() {
    let perDistance = UnitPreferences(language: "en", pace: .perDistance)
    #expect(formatSpeed(0, units: perDistance) == "")
    #expect(formatSpeed(-3, units: perDistance) == "")
    #expect(formatSpeed(1e-300, units: perDistance) == "")
    #expect(formatSpeed(nil, units: UnitPreferences(language: "en")) == "")
    let perLap = UnitPreferences(language: "en", pace: RestSchema.UnitPace(rawValue: "per-lap"))
    #expect(formatSpeed(4.5, units: perLap) == "4.5 km/h")
  }
}
