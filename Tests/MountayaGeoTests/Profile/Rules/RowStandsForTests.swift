import Testing

@testable import MountayaGeo

@Suite("rowStandsFor")
struct RowStandsForTests {
  @Test("a row answers to its own id and to a member it stands for, never to none")
  func standsFor() {
    let group = ItinerarySegmentRow(
      key: "group:g1", id: "group:g1", memberIds: ["s2", "s3"], name: "", index: 1, from: 0, to: 1,
      metrics: ItinerarySegmentRowMetrics())
    #expect(rowStandsFor(group, id: "group:g1") && rowStandsFor(group, id: "s3"))
    #expect(!rowStandsFor(group, id: "s9") && !rowStandsFor(group, id: nil))
    #expect(!rowStandsFor(group, id: "S3"))
  }
}
