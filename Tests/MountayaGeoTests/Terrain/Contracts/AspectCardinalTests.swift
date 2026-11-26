import Testing

@testable import MountayaGeo

@Suite("AspectCardinal")
struct AspectCardinalTests {
  @Test("the directions run clockwise from north, each spelled as the contract spells it")
  func clockwise() {
    #expect(
      AspectCardinal.allCases.map(\.rawValue) == ["N", "NE", "E", "SE", "S", "SW", "W", "NW"])
    #expect(AspectCardinal(rawValue: "SE") == .southEast)
    #expect(AspectCardinal(rawValue: "se") == nil)
  }
}
