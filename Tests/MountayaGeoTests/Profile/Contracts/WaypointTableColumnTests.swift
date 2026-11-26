import Testing

@testable import MountayaGeo

@Suite("WaypointTableColumn")
struct WaypointTableColumnTests {
  @Test("each column is spelled as the contract spells it")
  func spelling() {
    #expect(
      WaypointTableColumn.allCases.map(\.rawValue)
        == [
          "waypoint", "profile", "distance", "elevation", "altitude", "amenities", "cutoff",
          "properties",
        ])
  }
}
