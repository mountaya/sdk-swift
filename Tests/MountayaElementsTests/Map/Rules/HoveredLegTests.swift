import MountayaClient
import Testing

@testable import MountayaElements

@Suite("hoveredLeg")
struct HoveredLegTests {
  private func feature(_ properties: [String: JSONValue]) -> QueriedFeature {
    QueriedFeature(
      properties: properties, geometry: .point(GeoJSONPoint(coordinates: [6, 45])),
      layer: "itinerary-line")
  }

  @Test("the leg is the first a feature's segment id names, topmost first, and none without one")
  func leg() {
    #expect(
      hoveredLeg([
        feature(["waypoint_id": .string("hut")]), feature(["segment_id": .string("col")]),
        feature(["segment_id": .string("valley")]),
      ]) == "col")
    #expect(hoveredLeg([feature(["segment_id": .string("")])]) == nil)
    #expect(hoveredLeg([]) == nil)
  }
}
