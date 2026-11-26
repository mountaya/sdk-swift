import Testing

@testable import MountayaGeo

@Suite("ProfileWaypoint")
struct ProfileWaypointTests {
  @Test("two waypoints are equal when they are of one kind with one id and place, and hash alike")
  func equality() {
    let hut = ProfileWaypoint.atPosition(id: "hut", position: [6.8752, 45.9237])
    #expect(hut == .atPosition(id: "hut", position: [6.8752, 45.9237]))
    #expect(
      hut.hashValue == ProfileWaypoint.atPosition(id: "hut", position: [6.8752, 45.9237]).hashValue)
    #expect(
      ProfileWaypoint.atDistance(id: "hut", distance: 0) != .atPosition(id: "hut", position: [0]))
    #expect(
      ProfileWaypoint.atDistance(id: "marker", distance: 0)
        != .atDistance(id: "marker", distance: -0.0))
    #expect(
      ProfileWaypoint.atDistance(id: "marker", distance: .nan)
        == .atDistance(id: "marker", distance: .nan))
    #expect(
      String(describing: ProfileWaypoint.atDistance(id: "marker", distance: 1_200))
        == "atDistance(id: \"marker\", distance: 1200.0)")
    #expect(hut.id == "hut")
  }

  @Test("two waypoints are told apart by the scalars of their ids")
  func scalars() {
    #expect(
      ProfileWaypoint.atDistance(id: "\u{E9}", distance: 0)
        != .atDistance(id: "e\u{301}", distance: 0))
    #expect(
      ProfileWaypoint.atPosition(id: "\u{E9}", position: [6, 45])
        != .atPosition(id: "e\u{301}", position: [6, 45]))
  }
}
