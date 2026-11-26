import Testing

@testable import MountayaGeo

@Suite("mapSafeArea")
struct MapSafeAreaTests {
  /// window is what a phone with a Dynamic Island leaves visible of its window, in portrait.
  private let visible = ScreenRect(x: 0, y: 59, width: 393, height: 852 - 59 - 34)

  @Test("a map drawn full bleed takes the window's insets")
  func fullBleed() {
    #expect(
      mapSafeArea(ScreenRect(x: 0, y: 0, width: 393, height: 852), visible: visible)
        == PixelPadding(top: 59, right: 0, bottom: 34, left: 0))
  }

  @Test("a map laid inside the visible part has none, and one past its top the depth it reaches")
  func inside() {
    #expect(
      mapSafeArea(ScreenRect(x: 0, y: 100, width: 393, height: 400), visible: visible)
        == PixelPadding(0))
    #expect(
      mapSafeArea(ScreenRect(x: 0, y: 20, width: 393, height: 400), visible: visible).top == 39)
  }

  @Test("an inset is never deeper than the map")
  func shallow() {
    #expect(
      mapSafeArea(ScreenRect(x: 0, y: 0, width: 393, height: 30), visible: visible).top == 30)
  }
}
