import Testing

@testable import MountayaGeo

@Suite("ZoomBounds")
struct ZoomBoundsTests {
  @Test("two ranges are equal when they hold the same zooms, and hash alike")
  func equality() {
    #expect(ZoomBounds(minZoom: 3, maxZoom: 17) == ZoomBounds(minZoom: 3, maxZoom: 17))
    #expect(
      ZoomBounds(minZoom: 3, maxZoom: 17).hashValue == ZoomBounds(minZoom: 3, maxZoom: 17).hashValue
    )
    #expect(ZoomBounds(minZoom: 3, maxZoom: 17) != ZoomBounds(minZoom: 17, maxZoom: 3))
    #expect(ZoomBounds(minZoom: .nan, maxZoom: 17) == ZoomBounds(minZoom: .nan, maxZoom: 17))
    #expect(
      ZoomBounds(minZoom: .nan, maxZoom: 17).hashValue
        == ZoomBounds(minZoom: .nan, maxZoom: 17).hashValue)
    #expect(ZoomBounds(minZoom: 0, maxZoom: 17) != ZoomBounds(minZoom: -0.0, maxZoom: 17))
  }

  @Test("each zoom is named by the end it holds")
  func ends() {
    let bounds = ZoomBounds(minZoom: 6, maxZoom: 13)
    #expect([bounds.minZoom, bounds.maxZoom] == [6, 13])
    #expect(String(describing: bounds) == "ZoomBounds(minZoom: 6.0, maxZoom: 13.0)")
  }
}
