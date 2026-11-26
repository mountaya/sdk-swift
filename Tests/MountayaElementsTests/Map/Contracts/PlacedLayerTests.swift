import Testing

@testable import MountayaElements

@Suite("PlacedLayer")
struct PlacedLayerTests {
  @Test("a placed layer is its id and the rank it was placed at")
  func layer() {
    #expect(PlacedLayer(id: "hut", rank: 80) == PlacedLayer(id: "hut", rank: 80))
    #expect(PlacedLayer(id: "hut", rank: 80) != PlacedLayer(id: "hut", rank: 90))
  }
}
