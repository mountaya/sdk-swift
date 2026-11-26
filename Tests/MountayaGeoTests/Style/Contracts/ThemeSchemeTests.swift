import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ThemeScheme")
struct ThemeSchemeTests {
  @Test("the two schemes are spelled as the contract spells them")
  func spellings() {
    #expect(ThemeScheme.allCases.map(\.rawValue) == ["light", "dark"])
    #expect(ThemeScheme(rawValue: "dark") == .dark)
    #expect(ThemeScheme(rawValue: "Dark") == nil)
  }
}
