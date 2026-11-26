import Testing

@testable import MountayaGeo

@Suite("isSearchLimit")
struct IsSearchLimitTests {
  @Test("a cap is a whole number from one to the ceiling")
  func cap() {
    #expect(isSearchLimit(1))
    #expect(isSearchLimit(searchLimitMax))
    #expect(!isSearchLimit(0))
    #expect(!isSearchLimit(51))
    #expect(!isSearchLimit(-1))
    #expect(searchLimitMax == 50)
  }
}
