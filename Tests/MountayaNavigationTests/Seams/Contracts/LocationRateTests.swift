import Testing

@testable import MountayaNavigation

@Suite("LocationRate")
struct LocationRateTests {
  @Test("a rate is a navigation's or a walker's, a navigation's first")
  func cases() {
    #expect(LocationRate.allCases == [.navigation, .walking])
    #expect(LocationRate.allCases.map(\.rawValue) == ["navigation", "walking"])
  }
}
