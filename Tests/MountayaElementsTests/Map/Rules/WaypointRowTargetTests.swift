import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("waypointRowTarget")
struct WaypointRowTargetTests {
  @Test("a row pins the sample nearest its place's pass and lights no leg")
  func target() {
    let hut = ItineraryWaypointRow(
      key: "hut#0", place: ProfilePlace(.atDistance(id: "hut", distance: 700)), index: 1,
      from: 0, to: 700, metrics: ItineraryWaypointRowMetrics(distance: 700))
    #expect(
      waypointRowTarget(hut, series: rowTargetSeries) == MapTarget(lngLat: [6, 45.00675]))
    #expect(waypointRowTarget(nil, series: rowTargetSeries) == MapTarget())
  }
}
