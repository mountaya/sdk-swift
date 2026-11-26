import Testing

@testable import MountayaGeo

@Suite("roadAccessColor")
struct RoadAccessColorTests {
  @Test("each kind is drawn in its own opaque colour")
  func colors() {
    #expect(
      RoadAccessKind.allCases.map { roadAccessColor($0).hex } == [
        "#e03131", "#e8590c", "#9c36b5", "#1971c2", "#0c8599", "#495057",
      ])
    #expect(RoadAccessKind.allCases.allSatisfy { roadAccessColor($0).opacity == 1 })
    #expect(Set(RoadAccessKind.allCases.map { roadAccessColor($0).hex }).count == 6)
  }
}
