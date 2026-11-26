import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("AmenityFilter")
struct AmenityFilterTests {
  @Test("two filters are equal where they offer the same services over the same rows")
  func equality() {
    #expect(
      AmenityFilter(available: ["food", "water"], shown: [])
        == AmenityFilter(available: ["food", "water"], shown: []))
    #expect(
      AmenityFilter(available: ["food", "water"], shown: [])
        != AmenityFilter(available: ["water", "food"], shown: []))
  }
}
