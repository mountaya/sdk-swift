import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SegmentRowCell")
struct SegmentRowCellTests {
  @Test("a cell names its column")
  func column() {
    let cells: [SegmentRowCell] = [
      .segment(name: "Col"), .profile(lit: ProfileRange(from: 0, to: 1), color: nil),
      .distance(leg: nil, total: nil), .elevation(ascent: nil, descent: nil, totalAscent: nil),
      .altitude(band: nil, single: nil), .duration(seconds: nil), .difficulty(text: nil),
    ]
    #expect(cells.map(\.column) == SegmentTableColumn.allCases)
  }

  @Test("two cells are equal where they state the same in one column")
  func equality() {
    #expect(
      SegmentRowCell.distance(leg: 8_200, total: 24_300) == .distance(leg: 8_200, total: 24_300))
    #expect(SegmentRowCell.distance(leg: 8_200, total: nil) != .distance(leg: 8_200, total: 24_300))
    #expect(
      SegmentRowCell.altitude(band: AltitudeRange(min: 1, max: 2), single: nil)
        != .altitude(band: nil, single: 1))
    #expect(SegmentRowCell.difficulty(text: "T3") == .difficulty(text: "T3"))
    #expect(SegmentRowCell.segment(name: "a") != .difficulty(text: "a"))
    #expect(
      SegmentRowCell.duration(seconds: 3_600).hashValue
        == SegmentRowCell.duration(seconds: 3_600).hashValue)
  }
}
