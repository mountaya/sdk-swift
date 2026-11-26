import Testing

@testable import MountayaElements

@Suite("MapContent")
struct MapContentTests {
  @Test("a content holds its slot, its sources, its layers and its restricted stretches apart")
  func holds() {
    let content = MapContent(
      slot: .itinerary, sourceIds: ["itinerary"], layerIds: ["line", "point"],
      restrictionLayerIds: ["line__road-access-stripe", "line__road-access-icon"])

    #expect(content.slot == .itinerary)
    #expect(content.layerIds == ["line", "point"])
    #expect(content.restrictionLayerIds.count == 2)
    var other = content
    other.layerIds = ["line"]
    #expect(content != other)
  }
}
