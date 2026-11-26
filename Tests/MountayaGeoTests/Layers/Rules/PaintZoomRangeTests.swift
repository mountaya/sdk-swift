import Testing

@testable import MountayaGeo

@Suite("paintZoomRange")
struct PaintZoomRangeTests {
  @Test("the window runs from the lowest layer to the highest of every source")
  func window() {
    let sources = [
      TileFixtures.source([
        TileFixtures.layer("a", zoomMin: 10, zoomMax: 14),
        TileFixtures.layer("b", zoomMin: 12, zoomMax: 22),
      ]),
      TileFixtures.source([TileFixtures.layer("c", zoomMin: 6, zoomMax: 16)]),
    ]
    #expect(paintZoomRange(sources) == ZoomBounds(minZoom: 6, maxZoom: 22))
  }

  /// A source's own range says where its tiles are served and bounds nothing.
  @Test("a source's own range bounds nothing")
  func sourceRange() {
    let served = TileFixtures.source(
      [TileFixtures.layer("a", zoomMin: 8, zoomMax: 22)], zoomMin: 10, zoomMax: 15)
    #expect(
      paintZoomRange([served, TileFixtures.source([])]) == ZoomBounds(minZoom: 8, maxZoom: 22))
  }

  @Test("no layer paints at no zoom")
  func noLayer() {
    #expect(paintZoomRange([]) == nil)
    #expect(paintZoomRange([TileFixtures.source([])]) == nil)
  }
}
