import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("zoomWindowAfter")
struct ZoomWindowAfterTests {
  private static let glJs = ZoomBounds(minZoom: -2, maxZoom: 22)
  private static let native = ZoomBounds(minZoom: 0, maxZoom: 25.5)
  private static let held = ZoomBounds(minZoom: 8, maxZoom: 12)

  private static func kind(min: ZoomLimit, max: ZoomLimit, renderer: ZoomBounds = glJs)
    -> MapError.Kind?
  {
    do {
      _ = try zoomWindowAfter(held, min: min, max: max, renderer: renderer)
      return nil
    } catch {
      return error.kind
    }
  }

  @Test("each limit stated moves, each left out is kept, and a window above the one held is taken")
  func moves() throws {
    #expect(try zoomWindowAfter(Self.held, min: 8, max: 12, renderer: Self.glJs) == Self.held)
    #expect(
      try zoomWindowAfter(Self.held, min: .kept, max: 14, renderer: Self.glJs)
        == ZoomBounds(minZoom: 8, maxZoom: 14))
    #expect(
      try zoomWindowAfter(Self.held, min: .kept, max: .kept, renderer: Self.glJs) == Self.held)
    #expect(
      try zoomWindowAfter(
        ZoomBounds(minZoom: 2, maxZoom: 6), min: 10, max: 14, renderer: Self.glJs)
        == ZoomBounds(minZoom: 10, maxZoom: 14))
    #expect(
      try zoomWindowAfter(Self.held, min: 12, max: .kept, renderer: Self.glJs)
        == ZoomBounds(minZoom: 12, maxZoom: 12), "a window of one zoom")
  }

  @Test("a released limit goes back to the renderer's own, and is read as that zoom")
  func released() throws {
    #expect(
      try zoomWindowAfter(Self.held, min: 14, max: .released, renderer: Self.glJs)
        == ZoomBounds(minZoom: 14, maxZoom: 22))
    #expect(
      try zoomWindowAfter(Self.held, min: .released, max: .kept, renderer: Self.glJs)
        == ZoomBounds(minZoom: -2, maxZoom: 12))
    #expect(
      try zoomWindowAfter(Self.held, min: .released, max: .released, renderer: Self.native)
        == Self.native)
    #expect(
      Self.kind(min: .released, max: 1, renderer: ZoomBounds(minZoom: 3, maxZoom: 22))
        == .zoomBoundsRefused)
  }

  @Test("a limit no finite number is refused as a number, before any window is read")
  func numbers() {
    #expect(Self.kind(min: .zoom(.nan), max: .kept) == .numberRefused)
    #expect(Self.kind(min: .kept, max: .zoom(.infinity)) == .numberRefused)
    #expect(Self.kind(min: .zoom(-.infinity), max: 12) == .numberRefused)
    #expect(
      Self.kind(min: .zoom(.nan), max: 1) == .numberRefused, "a number refused before the window")
  }

  @Test(
    "a floor under the renderer's, above the ceiling stated or held, or a ceiling under the floor held, is refused"
  )
  func windows() {
    #expect(Self.kind(min: -3, max: .kept) == .zoomBoundsRefused)
    #expect(Self.kind(min: -2, max: .kept) == nil)
    #expect(Self.kind(min: -1, max: .kept, renderer: Self.native) == .zoomBoundsRefused)
    #expect(Self.kind(min: 0, max: .kept, renderer: Self.native) == nil)
    #expect(Self.kind(min: 13, max: .kept) == .zoomBoundsRefused)
    #expect(Self.kind(min: 10, max: 9) == .zoomBoundsRefused)
    #expect(Self.kind(min: .kept, max: 7) == .zoomBoundsRefused)
    #expect(Self.kind(min: .kept, max: 8) == nil)
  }
}
