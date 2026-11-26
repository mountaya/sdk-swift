import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("waypointDeclaresNothing")
struct WaypointDeclaresNothingTests {
  @Test("a place with no fact declares nothing, whatever its description")
  func nothing() {
    #expect(waypointDeclaresNothing(restWaypoint()))
    #expect(waypointDeclaresNothing(restWaypoint(description: "The old refuge above the glacier.")))
    #expect(
      waypointDeclaresNothing(restWaypoint(media: RestSchema.WaypointMedia { $0.photos = [] })))
    #expect(
      waypointDeclaresNothing(
        restWaypoint(media: RestSchema.WaypointMedia { $0.photos = .some(nil) })))
  }

  @Test("any service, timing, contact, media or field is a fact")
  func facts() {
    #expect(!waypointDeclaresNothing(restWaypoint(amenities: ["water"])))
    #expect(
      !waypointDeclaresNothing(
        restWaypoint(timing: RestSchema.WaypointTiming { $0.stop_duration = 60 })))
    #expect(
      !waypointDeclaresNothing(
        restWaypoint(contact: RestSchema.WaypointContact { $0.phone = "+33450123456" })))
    #expect(
      !waypointDeclaresNothing(
        restWaypoint(properties: [
          RestSchema.WaypointProperty(key: "beds", label: "Beds", value: "40")
        ])))
  }
}
