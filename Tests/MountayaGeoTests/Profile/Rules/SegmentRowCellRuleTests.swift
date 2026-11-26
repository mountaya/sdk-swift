import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("segmentRowCell")
struct SegmentRowCellRuleTests {
  private func row(
    color: String? = "#e8590c", min: Double? = 1_035, max: Double? = 1_850
  ) -> ItinerarySegmentRow {
    ItinerarySegmentRow(
      key: "s3", id: "s3", name: "Col de la Seigne", color: color, index: 2, from: 16_100,
      to: 24_300,
      metrics: ItinerarySegmentRowMetrics(
        distance: 24_300, sectionDistance: 8_200, ascent: 1_531, descent: 1_408,
        sectionAscent: 595, sectionDescent: 34, altitudeMin: min, altitudeMax: max,
        duration: 32_400, difficulty: "T3"))
  }

  @Test("the default columns, and every column of a leg")
  func columns() {
    #expect(defaultSegmentTableColumns == [.segment, .profile, .distance, .elevation])
    #expect(
      SegmentTableColumn.allCases.map { segmentRowCell(row(), column: $0) }
        == [
          .segment(name: "Col de la Seigne"),
          .profile(lit: ProfileRange(from: 16_100, to: 24_300), color: "#e8590c"),
          .distance(leg: 8_200, total: 24_300),
          .elevation(ascent: 595, descent: 34, totalAscent: 1_531),
          .altitude(band: AltitudeRange(min: 1_035, max: 1_850), single: nil),
          .duration(seconds: 32_400), .difficulty(text: "T3"),
        ])
  }

  @Test("a band with one end known states that end, the floor first, and none states none")
  func band() {
    #expect(
      segmentRowCell(row(min: nil), column: .altitude) == .altitude(band: nil, single: 1_850))
    #expect(
      segmentRowCell(row(max: nil), column: .altitude) == .altitude(band: nil, single: 1_035))
    #expect(
      segmentRowCell(row(max: .nan), column: .altitude) == .altitude(band: nil, single: 1_035))
    #expect(
      segmentRowCell(row(min: nil, max: nil), column: .altitude)
        == .altitude(band: nil, single: nil))
  }

  @Test("a leg with no colour is lit in the table's own")
  func colour() {
    #expect(
      segmentRowCell(row(color: nil), column: .profile)
        == .profile(lit: ProfileRange(from: 16_100, to: 24_300), color: nil))
  }
}
