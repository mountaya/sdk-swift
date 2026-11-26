import Testing

@testable import MountayaElements

@Suite("PointQuery")
struct PointQueryTests {
  @Test("a map answers four point queries")
  func queries() {
    #expect(PointQuery.allCases == [.features, .pois, .zones, .itineraries])
  }
}
