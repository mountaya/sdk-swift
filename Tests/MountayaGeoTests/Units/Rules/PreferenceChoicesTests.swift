import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("preferenceChoices")
struct PreferenceChoicesTests {
  /// checked is the value of each choice's checked option, in order, nil where none is.
  private static func checked(_ choices: [PreferenceChoice]) -> [String?] {
    choices.map { choice in choice.options.first(where: \.isChecked)?.value.rawValue }
  }

  @Test("five preferences, each option in the contract's order, a unit by its word")
  func order() {
    let choices = preferenceChoices(
      UnitPreferences(
        language: "de", length: .imperial, pace: .perDistance,
        slope: .percentage, temperature: .fahrenheit))

    #expect(choices.map(\.field) == [.length, .pace, .slope, .temperature, .language])
    #expect(choices[0].options.map(\.value.rawValue) == ["metric", "imperial"])
    #expect(choices[1].options.map(\.value.rawValue) == ["per-time", "per-distance"])
    #expect(choices[2].options.map(\.value.rawValue) == ["degrees", "percentage"])
    #expect(choices[3].options.map(\.value.rawValue) == ["celsius", "fahrenheit"])
    #expect(choices[4].options.map(\.value.rawValue) == ["en", "fr", "es", "it", "de", "zh", "ja"])
    #expect(
      choices.prefix(4).flatMap(\.options).map(\.label) == [
        .word("metric"), .word("imperial"), .word("perTime"), .word("perDistance"),
        .word("degrees"), .word("percentage"), .word("celsius"), .word("fahrenheit"),
      ])
    #expect(
      Self.checked(choices) == ["imperial", "per-distance", "percentage", "fahrenheit", "de"])
  }

  @Test("a language is named in itself, whatever language the reader reads")
  func endonyms() {
    let choices = preferenceChoices(UnitPreferences(language: "fr"))

    #expect(
      choices[4].options.map(\.label) == [
        .name("English"), .name("Français"), .name("Español"), .name("Italiano"),
        .name("Deutsch"), .name("中文"), .name("日本語"),
      ])
  }

  @Test("a language is checked as the map reads it, by its primary subtag")
  func languages() {
    #expect(Self.checked(preferenceChoices(UnitPreferences(language: "fr-CA")))[4] == "fr")
    #expect(Self.checked(preferenceChoices(UnitPreferences(language: "FR")))[4] == "fr")
    #expect(Self.checked(preferenceChoices(UnitPreferences(language: "zh-Hant-TW")))[4] == "zh")
    #expect(Self.checked(preferenceChoices(UnitPreferences(language: "pt-BR")))[4] == "en")
    #expect(Self.checked(preferenceChoices(UnitPreferences(language: "")))[4] == "en")
  }

  @Test("a unit the contract does not list checks none of its options")
  func unknownUnit() {
    let choices = preferenceChoices(
      UnitPreferences(language: "en", length: "nautical", temperature: "Celsius"))

    #expect(Self.checked(choices) == [nil, "per-time", "degrees", nil, "en"])
  }
}
