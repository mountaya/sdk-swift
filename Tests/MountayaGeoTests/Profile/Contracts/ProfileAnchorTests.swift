import Testing

@testable import MountayaGeo

@Suite("ProfileAnchor")
struct ProfileAnchorTests {
  @Test("each anchor is spelled as the contract spells it")
  func spelling() {
    #expect(ProfileAnchor.allCases.map(\.rawValue) == ["route", "sea-level", "window"])
    #expect(ProfileAnchor(rawValue: "sea-level") == .seaLevel)
    #expect(ProfileAnchor(rawValue: "seaLevel") == nil)
  }
}
