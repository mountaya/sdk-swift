import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("PreferenceValue")
struct PreferenceValueTests {
  @Test("a value names its preference and its wire spelling")
  func fields() {
    #expect(PreferenceValue.length(.imperial).field == .length)
    #expect(PreferenceValue.length(.imperial).rawValue == "imperial")
    #expect(PreferenceValue.pace(.perDistance).rawValue == "per-distance")
    #expect(PreferenceValue.slope(.percentage).field == .slope)
    #expect(PreferenceValue.temperature(.fahrenheit).field == .temperature)
    #expect(PreferenceValue.language(.fr).field == .language)
    #expect(PreferenceValue.language(.fr).rawValue == "fr")
  }

  @Test("two values are equal where they are of one preference and spell the same scalars")
  func equality() {
    #expect(PreferenceValue.language("fr") == .language(.fr))
    #expect(PreferenceValue.language("fr") != .language("fr-CA"))
    #expect(PreferenceValue.slope("degrees") != .temperature("degrees"))
    #expect(
      PreferenceValue.pace(.perTime).hashValue
        == PreferenceValue.pace("per-time").hashValue)
  }
}
