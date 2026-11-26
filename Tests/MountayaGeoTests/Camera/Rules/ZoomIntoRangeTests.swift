import Testing

@testable import MountayaGeo

@Suite("zoomIntoRange")
struct ZoomIntoRangeTests {
  private static let window = ZoomBounds(minZoom: 10, maxZoom: 14)

  @Test("a camera outside the window moves to its nearer edge")
  func outside() {
    #expect(zoomIntoRange(6, window: Self.window) == 10)
    #expect(zoomIntoRange(9.5, window: Self.window) == 10)
    #expect(zoomIntoRange(18, window: Self.window) == 14)
    #expect(zoomIntoRange(14.25, window: Self.window) == 14)
    #expect(zoomIntoRange(2, window: ZoomBounds(minZoom: -2, maxZoom: 0)) == 0)
  }

  @Test("a camera inside the window, its edges included, stays")
  func inside() {
    #expect(zoomIntoRange(12, window: Self.window) == nil)
    #expect(zoomIntoRange(10, window: Self.window) == nil)
    #expect(zoomIntoRange(14, window: Self.window) == nil)
  }

  @Test(
    "no move satisfies a window with an end that is no finite number or a floor above its ceiling")
  func noMove() {
    #expect(zoomIntoRange(6, window: ZoomBounds(minZoom: 12, maxZoom: 8)) == nil)
    #expect(zoomIntoRange(6, window: ZoomBounds(minZoom: 10, maxZoom: .infinity)) == nil)
    #expect(zoomIntoRange(18, window: ZoomBounds(minZoom: .nan, maxZoom: 14)) == nil)
    #expect(zoomIntoRange(.nan, window: Self.window) == nil)
  }
}
