import Testing

@testable import MountayaGeo

@Suite("isMarkerLabelShown")
struct IsMarkerLabelShownTests {
  @Test("a marker whose point stands on the map shows its label")
  func onTheMap() {
    #expect(isMarkerLabelShown(at: [200, 400], mapWidth: 390, mapHeight: 844))
    #expect(isMarkerLabelShown(at: [0, 0], mapWidth: 390, mapHeight: 844), "its top-left corner")
    #expect(
      isMarkerLabelShown(at: [389.5, 843.5], mapWidth: 390, mapHeight: 844),
      "just inside its bottom-right corner")
  }

  @Test("a marker whose point is off the map shows no label, never one held at the edge")
  func offTheMap() {
    #expect(!isMarkerLabelShown(at: [-1, 400], mapWidth: 390, mapHeight: 844), "past the left")
    #expect(!isMarkerLabelShown(at: [390, 400], mapWidth: 390, mapHeight: 844), "on the right")
    #expect(!isMarkerLabelShown(at: [200, -0.5], mapWidth: 390, mapHeight: 844), "above the top")
    #expect(!isMarkerLabelShown(at: [200, 900], mapWidth: 390, mapHeight: 844), "below the bottom")
  }

  @Test("a point that names no place shows no label")
  func nowhere() {
    #expect(!isMarkerLabelShown(at: [.nan, 10], mapWidth: 390, mapHeight: 844))
    #expect(!isMarkerLabelShown(at: [10, .infinity], mapWidth: 390, mapHeight: 844))
    #expect(!isMarkerLabelShown(at: [10], mapWidth: 390, mapHeight: 844))
    #expect(!isMarkerLabelShown(at: [10, 10], mapWidth: 0, mapHeight: 0), "a map of no size")
  }
}
