import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("WaypointRowCell")
struct WaypointRowCellTests {
  @Test("a cell names its column")
  func column() {
    let cells: [WaypointRowCell] = [
      .waypoint(glyph: "hut", name: nil), .profile(lit: ProfileRange(from: 0, to: 1)),
      .distance(total: 1), .elevation(ascent: nil, descent: nil), .altitude(nil), .amenities([]),
      .cutoff(moment: nil), .properties([]),
    ]
    #expect(cells.map(\.column) == WaypointTableColumn.allCases)
  }

  @Test("two cells are equal where they state the same in one column")
  func equality() {
    #expect(WaypointRowCell.waypoint(glyph: "hut", name: nil) == .waypoint(glyph: "hut", name: nil))
    #expect(
      WaypointRowCell.waypoint(glyph: "hut", name: nil) != .waypoint(glyph: "hut", name: "Hut"))
    #expect(WaypointRowCell.amenities(["water"]) != .amenities(["food"]))
    #expect(
      WaypointRowCell.cutoff(moment: "12:30").hashValue
        == WaypointRowCell.cutoff(moment: "12:30").hashValue)
  }
}
