import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("PreferenceLabel")
struct PreferenceLabelTests {
  @Test("two labels are equal where they are of one kind and spell the same scalars")
  func equality() {
    #expect(PreferenceLabel.word("metric") == .word("metric"))
    #expect(PreferenceLabel.word("metric") != .name("metric"))
    #expect(PreferenceLabel.name("Fran\u{E7}ais") != .name("Franc\u{327}ais"))
    #expect(PreferenceLabel.word("metric").hashValue == PreferenceLabel.word("metric").hashValue)
  }
}
