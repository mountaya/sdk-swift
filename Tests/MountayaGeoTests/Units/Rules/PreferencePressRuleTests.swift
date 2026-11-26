import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("preferencePress")
struct PreferencePressRuleTests {
  private static let held = UnitPreferences(
    language: "de", length: .imperial, pace: .perDistance,
    slope: .percentage, temperature: .fahrenheit)

  @Test("a press on a unit reports the set with that preference alone changed")
  func unit() {
    var expected = Self.held
    expected.length = .metric
    #expect(
      preferencePress(Self.held, pressing: .length(.metric))
        == PreferencePress(next: expected, relabel: nil))

    expected = Self.held
    expected.temperature = .celsius
    #expect(
      preferencePress(Self.held, pressing: .temperature(.celsius))
        == PreferencePress(next: expected, relabel: nil))
  }

  @Test("a press on a language reports the set and relabels the map in that language")
  func language() {
    var expected = Self.held
    expected.language = "fr"

    #expect(
      preferencePress(Self.held, pressing: .language(.fr))
        == PreferencePress(next: expected, relabel: .fr))
  }

  @Test("a press on a language the map does not label in relabels it as the map reads it")
  func regional() {
    var expected = Self.held
    expected.language = "fr-CA"
    #expect(
      preferencePress(Self.held, pressing: .language("fr-CA"))
        == PreferencePress(next: expected, relabel: .fr))

    expected.language = "pt-BR"
    #expect(
      preferencePress(Self.held, pressing: .language("pt-BR"))
        == PreferencePress(next: expected, relabel: .en))
  }

  @Test("a press on the option the set holds reports the set as it stands")
  func held() {
    #expect(
      preferencePress(Self.held, pressing: .slope(.percentage))
        == PreferencePress(next: Self.held, relabel: nil))
  }
}
