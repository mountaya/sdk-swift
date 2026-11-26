import Testing

@testable import MountayaGeo

@Suite("RoadAccessKind")
struct RoadAccessKindTests {
  @Test("the kinds are spelled by their ids, most severe first")
  func ids() {
    #expect(
      RoadAccessKind.allCases.map(\.id)
        == ["forbidden", "private", "permit", "service", "local-access", "restricted"])
    #expect(RoadAccessKind(rawValue: "local-access") == .localAccess)
  }

  @Test("of two kinds, the more severe is the lesser")
  func order() {
    #expect(RoadAccessKind.forbidden < .private)
    #expect(RoadAccessKind.localAccess < .restricted)
    #expect(min(RoadAccessKind.localAccess, .private) == .private)
    #expect(RoadAccessKind.allCases.sorted() == RoadAccessKind.allCases)
  }
}
