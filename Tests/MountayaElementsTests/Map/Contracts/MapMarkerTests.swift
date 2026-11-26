import MountayaElements
import Testing

@Suite("MapMarker")
struct MapMarkerTests {
  @Test("two markers are equal where every member is the same, a text by its scalars")
  func equality() {
    let hut = MapMarker(id: "hut", position: [6.86, 45.83], color: "#e64980", label: "Refuge")

    #expect(
      hut == MapMarker(id: "hut", position: [6.86, 45.83], color: "#e64980", label: "Refuge"))
    #expect(
      hut != MapMarker(id: "hut", position: [6.86, 45.84], color: "#e64980", label: "Refuge"))
    #expect(hut != MapMarker(id: "hut", position: [6.86, 45.83], label: "Refuge"))
    #expect(
      MapMarker(id: "caf\u{E9}", position: [0, 0])
        != MapMarker(id: "cafe\u{301}", position: [0, 0]))
    #expect(MapMarker(id: "a", position: [.nan, 0]) == MapMarker(id: "a", position: [.nan, 0]))
    #expect(MapMarker(id: "a", position: [0, 0]) != MapMarker(id: "a", position: [-0.0, 0]))
    #expect(
      MapMarker(id: "a", position: [0, 0], glyph: "hut")
        != MapMarker(id: "a", position: [0, 0], glyph: "mountain"))
    #expect(
      MapMarker(id: "a", position: [0, 0], glyph: "hut") != MapMarker(id: "a", position: [0, 0]))
  }
}
