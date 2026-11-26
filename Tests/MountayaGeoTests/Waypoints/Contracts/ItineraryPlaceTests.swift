import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ItineraryPlace")
struct ItineraryPlaceTests {
  private func place(
    id: String = "hut", lngLat: [Double] = [6.86, 45.83], name: String? = "Refuge de Miage",
    details: WaypointDetails? = WaypointDetails(description: "A bench")
  ) -> ItineraryPlace {
    ItineraryPlace(
      id: id, lngLat: lngLat, name: name, color: "#e03131", glyph: "hut", details: details)
  }

  @Test("two places are equal when every member is, and hash alike")
  func equality() {
    #expect(place() == place())
    #expect(place().hashValue == place().hashValue)
    #expect(place(lngLat: [.nan, 45]) == place(lngLat: [.nan, 45]))
    #expect(place(lngLat: [.nan, 45]).hashValue == place(lngLat: [.nan, 45]).hashValue)
    #expect(place(lngLat: [0, 45]) != place(lngLat: [-0.0, 45]))
    #expect(place(name: nil) != place())
    #expect(place(details: nil) != place())
  }

  @Test("an id and a name are compared scalar for scalar")
  func textsByScalars() {
    #expect(place(id: "caf\u{E9}") != place(id: "cafe\u{301}"))
    #expect(place(name: "Ch\u{E2}let") != place(name: "Cha\u{302}let"))
  }

  @Test("a place built from its id and position states nothing else")
  func defaults() {
    let bare = ItineraryPlace(id: "pin", lngLat: [6, 45])

    #expect(bare.name == nil && bare.color == nil && bare.glyph == nil && bare.details == nil)
  }
}
