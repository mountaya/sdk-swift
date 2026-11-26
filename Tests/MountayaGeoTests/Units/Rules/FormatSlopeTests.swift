import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatSlope")
struct FormatSlopeTests {
  private let grade = UnitPreferences(language: "en", slope: .percentage)
  private let angle = UnitPreferences(language: "en", slope: .degrees)

  @Test("a grade is the tangent times a hundred")
  func grades() {
    #expect(formatSlope(12.5, units: grade) == "22%")
    #expect(formatSlope(45, units: grade) == "100%")
    #expect(formatSlope(-12.5, units: grade) == "-22%")
    #expect(
      formatSlope(12.5, units: UnitPreferences(language: "fr", slope: .percentage))
        == "22\u{A0}%")
  }

  @Test("an angle takes the degree sign in every language")
  func angles() {
    #expect(formatSlope(12.5, units: angle) == "13°")
    #expect(formatSlope(12.5, units: UnitPreferences(language: "fr")) == "13°")
    #expect(formatSlope(-12.5, units: angle) == "-13°")
  }

  @Test("a slope that rounds to zero is level and takes no sign")
  func level() {
    #expect(formatSlope(-0.3, units: angle) == "0°")
    #expect(formatSlope(-0.2, units: grade) == "0%")
    #expect(formatSlope(nil, units: grade) == "")
    let gradians = UnitPreferences(
      language: "en", slope: RestSchema.UnitSlope(rawValue: "gradians"))
    #expect(formatSlope(12.5, units: gradians) == "13°")
  }
}
