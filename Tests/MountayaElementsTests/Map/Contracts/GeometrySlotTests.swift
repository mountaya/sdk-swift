import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("GeometrySlot")
struct GeometrySlotTests {
  @Test(
    "the highlight draws at the chrome band, the preview and the emphasis just above the itinerary")
  func ranks() {
    #expect(GeometrySlot.highlight.rank == LayerRank.chrome.rank)
    #expect(GeometrySlot.highlight.rank == 100)
    #expect(GeometrySlot.preview.rank == LayerRank.itineraryFocus.rank)
    #expect(GeometrySlot.emphasis.rank == 52)
    #expect(GeometrySlot.preview.rank > LayerRank.itineraryLine.rank)
    #expect(GeometrySlot.preview.rank < LayerRank.itineraryRestriction.rank)
  }

  @Test("each slot has its own colour and draws from a source named after it")
  func colours() {
    #expect(GeometrySlot.allCases.map(\.rawValue) == ["preview", "highlight", "emphasis"])
    #expect(GeometrySlot.allCases.map(\.color) == ["#2b8a3e", "#f59f00", "#e9501e"])
    #expect(
      GeometrySlot.allCases.map(\.sourceId) == [
        "mountaya-preview", "mountaya-highlight", "mountaya-emphasis",
      ])
  }
}
