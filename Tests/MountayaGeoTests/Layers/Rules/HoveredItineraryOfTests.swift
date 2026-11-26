import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("hoveredItineraryOf")
struct HoveredItineraryOfTests {
  @Test(
    "the first leg and the first place named, topmost first, a feature naming both answering both")
  func firstNamed() {
    #expect(
      hoveredItineraryOf([
        ["waypoint_id": "hut"], ["segment_id": "climb"], ["segment_id": "descent"],
      ])
        == HoveredItinerary(segmentId: "climb", waypointId: "hut"))
    #expect(
      hoveredItineraryOf([
        ["segment_id": "climb", "waypoint_id": "col"], ["segment_id": "descent"],
      ])
        == HoveredItinerary(segmentId: "climb", waypointId: "col"))
  }

  @Test("a value that is no id, an empty one or one of another type, gives way to the next")
  func noId() {
    #expect(
      hoveredItineraryOf([["segment_id": ""], ["segment_id": 7]]) == HoveredItinerary())
    #expect(
      hoveredItineraryOf([
        ["zone_id": "z-1"], [:], ["segment_id": "descent", "waypoint_id": ""],
        ["waypoint_id": "lake"],
      ]) == HoveredItinerary(segmentId: "descent", waypointId: "lake"))
    #expect(
      hoveredItineraryOf([["segment_id": .null, "waypoint_id": ["hut"]]]) == HoveredItinerary())
  }

  @Test("a feature's own id is never read, and no feature names nothing")
  func ownId() {
    #expect(hoveredItineraryOf([["name": "Climb", "id": "climb"]]) == HoveredItinerary())
    #expect(hoveredItineraryOf([]) == HoveredItinerary())
    #expect(segmentIdProperty == "segment_id")
    #expect(waypointIdProperty == "waypoint_id")
  }
}
