import Testing

@testable import MountayaGeo

@Suite("ItineraryWaypointRowMetrics")
struct ItineraryWaypointRowMetricsTests {
  @Test("every figure but the distance is nil unless given, and equal by number")
  func equality() {
    let metrics = ItineraryWaypointRowMetrics(distance: 300)
    #expect(metrics.sectionDistance == nil && metrics.altitude == nil && metrics.ascent == nil)
    #expect(metrics == ItineraryWaypointRowMetrics(distance: 300))
    #expect(metrics != ItineraryWaypointRowMetrics(distance: 300, altitude: 1_000))
    #expect(ItineraryWaypointRowMetrics(distance: 0) != ItineraryWaypointRowMetrics(distance: -0.0))
    #expect(metrics.hashValue == ItineraryWaypointRowMetrics(distance: 300).hashValue)
  }
}
