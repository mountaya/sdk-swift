import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchHighlight")
struct SearchHighlightTests {
  @Test("two highlights are equal where they hold the same values, each number the same number")
  func equality() {
    #expect(SearchHighlight.place(point: [6, .nan]) == .place(point: [6, .nan]))
    #expect(SearchHighlight.place(point: [0, 45]) != .place(point: [-0.0, 45]))
    #expect(
      SearchHighlight.poi(point: [6, 45], category: .hut)
        == .poi(point: [6, 45], category: .hut))
    #expect(
      SearchHighlight.poi(point: [6, 45], category: .hut) != .poi(point: [6, 45], category: nil))
    #expect(SearchHighlight.poi(point: [6, 45], category: nil) != .place(point: [6, 45]))
    #expect(
      SearchHighlight.way(anchor: [6, 45], bounds: [6, 45, 7, 46], coordinates: [[6, .nan]])
        == .way(anchor: [6, 45], bounds: [6, 45, 7, 46], coordinates: [[6, .nan]]))
    #expect(
      SearchHighlight.way(anchor: [6, 45], bounds: nil, coordinates: nil)
        != .way(anchor: [6, 45], bounds: nil, coordinates: []))
    #expect(
      SearchHighlight.way(anchor: [6, .nan], bounds: nil, coordinates: nil).hashValue
        == SearchHighlight.way(anchor: [6, .nan], bounds: nil, coordinates: nil).hashValue)
  }

  @Test("a category is told apart by its scalars")
  func scalars() {
    #expect(
      SearchHighlight.poi(point: [6, 45], category: DataSchema.POICategory(rawValue: "CAF\u{C9}"))
        != .poi(point: [6, 45], category: DataSchema.POICategory(rawValue: "CAFE\u{301}")))
  }
}
