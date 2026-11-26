import Testing

@testable import MountayaGeo

@Suite("HoveredItinerary")
struct HoveredItineraryTests {
  @Test("two readings are equal where they name the same leg and place")
  func equality() {
    #expect(HoveredItinerary() == HoveredItinerary(segmentId: nil, waypointId: nil))
    #expect(HoveredItinerary(segmentId: "climb") != HoveredItinerary(waypointId: "climb"))
  }
}
