import Testing

@testable import MountayaGeo

@Suite("effectiveZoomBounds")
struct EffectiveZoomBoundsTests {
  @Test("the minimum is floored and the maximum buffered")
  func flooredAndBuffered() {
    #expect(effectiveZoomBounds(zoomMin: 0, zoomMax: 18) == ZoomBounds(minZoom: 3, maxZoom: 17))
    #expect(effectiveZoomBounds(zoomMin: 6, zoomMax: 14) == ZoomBounds(minZoom: 6, maxZoom: 13))
    #expect(effectiveZoomBounds(zoomMin: 3, zoomMax: 5) == ZoomBounds(minZoom: 3, maxZoom: 4))
  }

  /// The minimum is the end that bounds how far a camera pulls out, so it keeps its value and the
  /// maximum widens the range.
  @Test("a narrow range is widened at its maximum")
  func narrow() {
    #expect(effectiveZoomBounds(zoomMin: 4, zoomMax: 5) == ZoomBounds(minZoom: 4, maxZoom: 5))
    #expect(effectiveZoomBounds(zoomMin: 22, zoomMax: 22) == ZoomBounds(minZoom: 22, maxZoom: 23))
    #expect(effectiveZoomBounds(zoomMin: 0, zoomMax: 2) == ZoomBounds(minZoom: 3, maxZoom: 4))
  }

  @Test("a fractional range is held as written")
  func fractional() {
    #expect(
      effectiveZoomBounds(zoomMin: 4.5, zoomMax: 16.25) == ZoomBounds(minZoom: 4.5, maxZoom: 15.25))
  }

  @Test("nothing is refused or ordered, and NaN is kept whichever side of the floor it is on")
  func nothingRefused() {
    #expect(effectiveZoomBounds(zoomMin: 10, zoomMax: 2) == ZoomBounds(minZoom: 10, maxZoom: 11))
    #expect(
      effectiveZoomBounds(zoomMin: .nan, zoomMax: 18) == ZoomBounds(minZoom: .nan, maxZoom: .nan))
    #expect(effectiveZoomBounds(zoomMin: 0, zoomMax: .nan) == ZoomBounds(minZoom: 3, maxZoom: .nan))
  }

  @Test("the floor, the buffer and the span are the fixture's own")
  func constants() {
    #expect(effectiveMinZoomFloor == 3)
    #expect(zoomBuffer == 1)
    #expect(effectiveZoomMinSpan == 1)
  }
}
