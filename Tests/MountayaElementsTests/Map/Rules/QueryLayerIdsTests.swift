import Testing

@testable import MountayaElements

@Suite("queryLayerIds")
struct QueryLayerIdsTests {
  private static let placed = [
    PlacedLayer(id: "itinerary-line", rank: 50), PlacedLayer(id: "itinerary-point", rank: 90),
    PlacedLayer(id: "zone-fill", rank: 40), PlacedLayer(id: "hut", rank: 80),
  ]

  @Test("each query asks about its bands the live style holds, in the order the map placed them")
  func bands() {
    let live: Set<String> = ["background", "road-label", "itinerary-line", "zone-fill", "hut"]
    #expect(
      queryLayerIds(.features, placed: Self.placed, isLive: live.contains)
        == ["itinerary-line", "zone-fill", "hut"])
    #expect(queryLayerIds(.pois, placed: Self.placed, isLive: live.contains) == ["hut"])
    #expect(queryLayerIds(.zones, placed: Self.placed, isLive: live.contains) == ["zone-fill"])
    #expect(
      queryLayerIds(.itineraries, placed: Self.placed, isLive: { _ in true })
        == ["itinerary-line", "itinerary-point"])
  }

  @Test("a rank between two bands is in neither, and a query left with no layer asks nothing")
  func nothing() {
    let between = [PlacedLayer(id: "itinerary-line", rank: 50), PlacedLayer(id: "mine", rank: 52)]
    #expect(
      queryLayerIds(.itineraries, placed: between, isLive: { _ in true }) == ["itinerary-line"])
    #expect(
      queryLayerIds(.features, placed: between, isLive: { _ in true }) == [
        "itinerary-line", "mine",
      ])
    #expect(queryLayerIds(.pois, placed: between, isLive: { _ in true }) == nil)
    #expect(queryLayerIds(.features, placed: Self.placed, isLive: { _ in false }) == nil)
    #expect(queryLayerIds(.features, placed: [], isLive: { _ in true }) == nil)
  }
}
