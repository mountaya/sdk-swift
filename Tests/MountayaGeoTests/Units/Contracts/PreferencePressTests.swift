import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("PreferencePress")
struct PreferencePressTests {
  @Test("two presses are equal where they ask for the same set and the same relabelling")
  func equality() {
    let set = UnitPreferences(language: "fr")

    #expect(
      PreferencePress(next: set, relabel: .fr) == PreferencePress(next: set, relabel: "fr"))
    #expect(PreferencePress(next: set, relabel: nil) != PreferencePress(next: set, relabel: "fr"))
    #expect(
      PreferencePress(next: set, relabel: nil)
        != PreferencePress(next: UnitPreferences(language: "de"), relabel: nil))
  }
}
