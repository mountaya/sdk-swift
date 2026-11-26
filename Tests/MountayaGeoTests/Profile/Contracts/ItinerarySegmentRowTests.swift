import Testing

@testable import MountayaGeo

@Suite("ItinerarySegmentRow")
struct ItinerarySegmentRowTests {
  private func row(memberIds: [String] = [], color: String? = nil) -> ItinerarySegmentRow {
    ItinerarySegmentRow(
      key: "group:g1", id: "group:g1", memberIds: memberIds, name: "Over the col", color: color,
      index: 1, from: 1_000, to: 3_000, metrics: ItinerarySegmentRowMetrics(sectionDistance: 2_000))
  }

  @Test("a row is a span of the axis")
  func span() {
    let span: any ProfileSpan = row()
    #expect(span.from == 1_000 && span.to == 3_000)
  }

  @Test("two rows are equal where every member is")
  func equality() {
    #expect(row(memberIds: ["s2", "s3"]) == row(memberIds: ["s2", "s3"]))
    #expect(row(memberIds: ["s2", "s3"]).hashValue == row(memberIds: ["s2", "s3"]).hashValue)
    #expect(row(memberIds: ["s2", "s3"]) != row(memberIds: ["s3", "s2"]))
    #expect(row(color: "#e8590c") != row())
  }
}
