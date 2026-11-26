import Testing

@testable import MountayaGeo

@Suite("ItineraryWaypointRow")
struct ItineraryWaypointRowTests {
  @Test("a row is the span reaching its place, and equal where every member is")
  func equality() {
    let hut = ProfilePlace(.atDistance(id: "hut", distance: 200), name: "Hut")
    let row = ItineraryWaypointRow(
      key: "hut#0", place: hut, index: 0, from: 0, to: 200,
      metrics: ItineraryWaypointRowMetrics(distance: 200))
    let span: any ProfileSpan = row
    #expect(span.from == 0 && span.to == 200)
    #expect(
      row
        == ItineraryWaypointRow(
          key: "hut#0", place: hut, index: 0, from: 0, to: 200,
          metrics: ItineraryWaypointRowMetrics(distance: 200)))
    #expect(
      row
        != ItineraryWaypointRow(
          key: "hut#1", place: hut, index: 0, from: 0, to: 200,
          metrics: ItineraryWaypointRowMetrics(distance: 200)))
  }
}
