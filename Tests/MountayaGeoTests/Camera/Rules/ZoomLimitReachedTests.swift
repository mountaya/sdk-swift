import Testing

@testable import MountayaGeo

@Suite("zoomLimitReached")
struct ZoomLimitReachedTests {
  private static let window = ZoomBounds(minZoom: 10, maxZoom: 14)

  @Test("a camera stands at an end at it or past it, and at neither a fraction inside")
  func ends() {
    #expect(zoomLimitReached(14, window: Self.window) == .ceiling)
    #expect(zoomLimitReached(14.5, window: Self.window) == .ceiling)
    #expect(zoomLimitReached(10, window: Self.window) == .floor)
    #expect(zoomLimitReached(9, window: Self.window) == .floor)
    #expect(zoomLimitReached(12, window: Self.window) == ZoomWindowEnd.none)
    #expect(zoomLimitReached(13.999, window: Self.window) == ZoomWindowEnd.none)
    #expect(zoomLimitReached(10.001, window: Self.window) == ZoomWindowEnd.none)
    #expect(zoomLimitReached(12, window: ZoomBounds(minZoom: 12, maxZoom: 12)) == .both)
    #expect(zoomLimitReached(-2, window: ZoomBounds(minZoom: -2, maxZoom: 22)) == .floor)
    #expect(zoomLimitReached(22, window: ZoomBounds(minZoom: -2, maxZoom: 22)) == .ceiling)
    #expect(zoomLimitReached(.nan, window: Self.window) == ZoomWindowEnd.none)
  }

  @Test("the control toward an end the camera stands at is disabled")
  func disabled() {
    #expect(zoomControlsDisabled(at: ZoomWindowEnd.none) == [])
    #expect(zoomControlsDisabled(at: .floor) == [.zoomOut])
    #expect(zoomControlsDisabled(at: .ceiling) == [.zoomIn])
    #expect(zoomControlsDisabled(at: .both) == [.zoomIn, .zoomOut])
  }
}
