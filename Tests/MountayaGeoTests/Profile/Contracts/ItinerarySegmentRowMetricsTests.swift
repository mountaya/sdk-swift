import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ItinerarySegmentRowMetrics")
struct ItinerarySegmentRowMetricsTests {
  @Test("every figure is nil unless given")
  func defaults() {
    let metrics = ItinerarySegmentRowMetrics()
    #expect(metrics.distance == nil && metrics.sectionDistance == nil && metrics.ascent == nil)
    #expect(metrics.descent == nil && metrics.sectionAscent == nil && metrics.sectionDescent == nil)
    #expect(metrics.altitudeMin == nil && metrics.altitudeMax == nil && metrics.duration == nil)
    #expect(metrics.difficulty == nil)
  }

  @Test("two are equal where every figure is the same, or absent on both")
  func equality() {
    let stated = ItinerarySegmentRowMetrics(
      sectionDistance: 4_200, duration: 3_600, difficulty: "T3")
    #expect(
      stated
        == ItinerarySegmentRowMetrics(sectionDistance: 4_200, duration: 3_600, difficulty: "T3"))
    #expect(
      stated.hashValue
        == ItinerarySegmentRowMetrics(sectionDistance: 4_200, duration: 3_600, difficulty: "T3")
        .hashValue)
    #expect(stated != ItinerarySegmentRowMetrics(sectionDistance: 4_200, duration: 3_600))
    #expect(ItinerarySegmentRowMetrics(ascent: 0) != ItinerarySegmentRowMetrics(ascent: -0.0))
    #expect(ItinerarySegmentRowMetrics(ascent: 0) != ItinerarySegmentRowMetrics())
  }
}
