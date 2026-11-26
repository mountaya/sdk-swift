import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("UnitPreferences")
struct UnitPreferencesTests {
  @Test("a reader who says nothing but the language reads metric, per time, degrees and Celsius")
  func defaults() {
    let preferences = UnitPreferences(language: "en")
    #expect(preferences.length == .metric)
    #expect(preferences.pace == .perTime)
    #expect(preferences.slope == .degrees)
    #expect(preferences.temperature == .celsius)
  }

  @Test("two preferences are equal when every field is, and hash alike")
  func equality() {
    let imperial = UnitPreferences(language: "fr", length: .imperial)
    let spelled = UnitPreferences(
      language: "fr", length: RestSchema.UnitLength(rawValue: "imperial"))
    #expect(imperial == spelled)
    #expect(imperial.hashValue == spelled.hashValue)
    #expect(imperial != UnitPreferences(language: "fr"))
    #expect(imperial != UnitPreferences(language: "en", length: .imperial))
  }

  @Test("two preferences are told apart by the scalars of their language and their units")
  func scalars() {
    #expect(UnitPreferences(language: "\u{E9}") != UnitPreferences(language: "e\u{301}"))
    #expect(
      UnitPreferences(language: "fr", length: RestSchema.UnitLength(rawValue: "\u{E9}"))
        != UnitPreferences(language: "fr", length: RestSchema.UnitLength(rawValue: "e\u{301}")))
    #expect(
      UnitPreferences(language: "fr", pace: RestSchema.UnitPace(rawValue: "\u{E9}"))
        != UnitPreferences(language: "fr", pace: RestSchema.UnitPace(rawValue: "e\u{301}")))
    #expect(
      UnitPreferences(language: "fr", slope: RestSchema.UnitSlope(rawValue: "\u{E9}"))
        != UnitPreferences(language: "fr", slope: RestSchema.UnitSlope(rawValue: "e\u{301}")))
    #expect(
      UnitPreferences(language: "fr", temperature: RestSchema.UnitTemperature(rawValue: "\u{E9}"))
        != UnitPreferences(
          language: "fr", temperature: RestSchema.UnitTemperature(rawValue: "e\u{301}")))
  }
}
