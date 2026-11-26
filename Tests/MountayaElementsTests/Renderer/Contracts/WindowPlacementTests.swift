import Testing

@testable import MountayaElements
@testable import MountayaGeo

@Suite("WindowPlacement")
struct WindowPlacementTests {
  @Test("a view's safe area is the depth it reaches past the part of its window left visible")
  func safeArea() {
    let visible = ScreenRect(x: 0, y: 59, width: 390, height: 751)
    let fullBleed = WindowPlacement(
      view: ScreenRect(x: 0, y: 0, width: 390, height: 844), visible: visible)
    #expect(fullBleed.safeArea == PixelPadding(top: 59, right: 0, bottom: 34, left: 0))
    let inside = WindowPlacement(
      view: ScreenRect(x: 0, y: 120, width: 390, height: 400), visible: visible)
    #expect(inside.safeArea == PixelPadding(0), "a view inside the visible part has no inset")
  }
}
