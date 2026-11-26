import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ProfilePlace")
struct ProfilePlaceTests {
  @Test(
    "a named place divides the itinerary unless it says otherwise, a bare marker only where it says so"
  )
  func divides() {
    #expect(ProfilePlace(.atDistance(id: "col", distance: 500), name: "Col").dividesRoute)
    #expect(!ProfilePlace(.atDistance(id: "water", distance: 200)).dividesRoute)
    #expect(
      !ProfilePlace(.atDistance(id: "spring", distance: 150), name: "Spring", divides: false)
        .dividesRoute)
    #expect(ProfilePlace(.atDistance(id: "marker", distance: 350), divides: true).dividesRoute)
  }

  @Test(
    "an itinerary's place stands at its position with its name, colour, glyph and details, pinned")
  func fromItineraryPlace() {
    let details = WaypointDetails(amenities: [.water])
    let place = ProfilePlace(
      ItineraryPlace(
        id: "hut", lngLat: [6.8652, 45.9237], name: "Hut", color: "#e8590c", glyph: "hut",
        details: details))
    #expect(place.placement == .atPosition(id: "hut", position: [6.8652, 45.9237]))
    #expect(place.id == "hut" && place.name == "Hut" && place.color == "#e8590c")
    #expect(place.glyph == "hut" && place.details == details)
    #expect(place.isPinned && place.divides == nil && place.metrics == nil)
  }

  @Test("two places are equal where every member is the same")
  func equality() {
    let place = ProfilePlace(.atDistance(id: "col", distance: 500), name: "Col", isPinned: false)
    #expect(
      place == ProfilePlace(.atDistance(id: "col", distance: 500), name: "Col", isPinned: false))
    #expect(
      place.hashValue
        == ProfilePlace(.atDistance(id: "col", distance: 500), name: "Col", isPinned: false)
        .hashValue)
    #expect(place != ProfilePlace(.atDistance(id: "col", distance: 500), name: "Col"))
    #expect(
      place
        != ProfilePlace(
          .atDistance(id: "col", distance: 500), name: "Col", isPinned: false,
          metrics: ItinerarySegmentRowMetrics(ascent: 250)))
  }
}
