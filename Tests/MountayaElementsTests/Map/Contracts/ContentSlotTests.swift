import Testing

@testable import MountayaElements

@Suite("ContentSlot")
struct ContentSlotTests {
  @Test("two slots are one where they are of one kind and name the same, by its scalars")
  func equality() {
    #expect(ContentSlot.itinerary == .itinerary)
    #expect(ContentSlot.itinerary != .collection)
    #expect(ContentSlot.itineraries != .zones)
    #expect(ContentSlot.enrichment("hillshade") == .enrichment("hillshade"))
    #expect(ContentSlot.enrichment("hillshade") != .specification("hillshade"))
    #expect(ContentSlot.specification("caf\u{E9}") != .specification("cafe\u{301}"))
    #expect(ContentSlot.overlay != .enrichment("overlay"))
    #expect(ContentSlot.searchHighlight == .searchHighlight)
    #expect(ContentSlot.searchHighlight != .geometry(.highlight))
  }
}
