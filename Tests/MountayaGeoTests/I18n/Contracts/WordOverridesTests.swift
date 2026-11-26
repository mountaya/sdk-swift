import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("WordOverrides")
struct WordOverridesTests {
  @Test("two overrides are equal where they are one shape holding the same words")
  func equality() {
    #expect(WordOverrides.bySection([:]) == .bySection([:]))
    #expect(WordOverrides.byLanguage([.fr: [:]]) == .byLanguage([.fr: [:]]))
    #expect(WordOverrides.bySection([:]) != .byLanguage([:]))
    #expect(
      WordOverrides.byLanguage([.fr: ["title": "Plan"]]).hashValue
        == WordOverrides.byLanguage([.fr: ["title": "Plan"]]).hashValue)
  }
}
