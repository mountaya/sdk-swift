import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatTemperature")
struct FormatTemperatureTests {
  @Test("a temperature is whole degrees in the scale asked")
  func wholeDegrees() {
    #expect(formatTemperature(4, units: UnitPreferences(language: "en")) == "4°C")
    #expect(
      formatTemperature(
        4, units: UnitPreferences(language: "en", temperature: .fahrenheit))
        == "39°F")
    #expect(formatTemperature(-12.4, units: UnitPreferences(language: "en")) == "-12°C")
  }

  /// Temperature is never derived from length.
  @Test("an imperial reader who stored Celsius is shown Celsius")
  func independent() {
    let reader = UnitPreferences(language: "fr", length: .imperial)
    #expect(formatTemperature(4, units: reader) == "4\u{202F}°C")
  }

  @Test("a temperature that rounds to zero has no sign, and an unknown scale is Celsius")
  func zeroAndUnknown() {
    #expect(formatTemperature(-0.4, units: UnitPreferences(language: "en")) == "0°C")
    let kelvin = UnitPreferences(
      language: "en", temperature: RestSchema.UnitTemperature(rawValue: "kelvin"))
    #expect(formatTemperature(4, units: kelvin) == "4°C")
    #expect(formatTemperature(.nan, units: UnitPreferences(language: "en")) == "")
  }
}
