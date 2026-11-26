import Testing

@testable import MountayaGeo

@Suite("ClimbCategory")
struct ClimbCategoryTests {
  @Test("the categories run in ascending severity, each from its score")
  func severity() {
    #expect(ClimbCategory.allCases.map(\.id) == ["4", "3", "2", "1", "hc"])
    #expect(ClimbCategory.allCases.map(\.minimumScore) == [8_000, 16_000, 32_000, 64_000, 80_000])
    #expect(ClimbCategory(rawValue: "hc") == .horsCategorie)
  }
}
