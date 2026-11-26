import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("PreferenceField")
struct PreferenceFieldTests {
  @Test("the five preferences in the order a picker offers them, spelled as the contract does")
  func spellings() {
    #expect(
      PreferenceField.allCases.map(\.rawValue)
        == ["length", "pace", "slope", "temperature", "language"])
  }
}
