import Testing

@testable import MountayaGeo

@Suite("PlacedWaypoint")
struct PlacedWaypointTests {
  private let hut = ProfileWaypoint.atPosition(id: "hut", position: [6.8752, 45.9237])

  @Test("two placements are equal when they hold one key, waypoint and distance, and hash alike")
  func equality() {
    let placed = PlacedWaypoint(key: "hut#1", waypoint: hut, distance: 6_130.7)
    #expect(placed == PlacedWaypoint(key: "hut#1", waypoint: hut, distance: 6_130.7))
    #expect(
      placed.hashValue == PlacedWaypoint(key: "hut#1", waypoint: hut, distance: 6_130.7).hashValue)
    #expect(placed != PlacedWaypoint(key: "hut#0", waypoint: hut, distance: 6_130.7))
    #expect(
      String(describing: PlacedWaypoint(key: "hut#0", waypoint: hut, distance: 773.4))
        == "PlacedWaypoint(key: \"hut#0\", waypoint: MountayaGeo.ProfileWaypoint.atPosition(id: \"hut\", position: [6.8752, 45.9237]), distance: 773.4)"
    )
  }

  @Test("two placements are told apart by the scalars of their keys")
  func scalars() {
    #expect(
      PlacedWaypoint(key: "\u{E9}#0", waypoint: hut, distance: 0)
        != PlacedWaypoint(key: "e\u{301}#0", waypoint: hut, distance: 0))
  }
}
