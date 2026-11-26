import MountayaElements
import Testing

@Suite("WaypointEdit")
struct WaypointEditTests {
  @Test("an edit is the waypoint, where it was placed, and whether the magnet placed it")
  func equality() {
    let edit = WaypointEdit(waypointId: "w1", position: [6.86, 45.83], isSnapped: true)

    #expect(edit == WaypointEdit(waypointId: "w1", position: [6.86, 45.83], isSnapped: true))
    #expect(edit != WaypointEdit(waypointId: "w1", position: [6.86, 45.83]))
    #expect(edit != WaypointEdit(waypointId: "w1", isSnapped: true), "a place against none")
    #expect(WaypointEdit(waypointId: "w1") == WaypointEdit(waypointId: "w1"))
    #expect(WaypointEdit(waypointId: "caf\u{E9}") != WaypointEdit(waypointId: "cafe\u{301}"))
  }
}
