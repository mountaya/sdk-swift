import Testing

@testable import MountayaGeo

@Suite("safeAreaBounds")
struct SafeAreaBoundsTests {
  @Test("the safe area stands its insets inside the map's edges")
  func inset() {
    #expect(
      safeAreaBounds(PixelPadding(top: 59, right: 0, bottom: 34, left: 0), width: 390, height: 844)
        == ScreenRect(x: 0, y: 59, width: 390, height: 751))
    #expect(
      safeAreaBounds(PixelPadding(0), width: 390, height: 844)
        == ScreenRect(x: 0, y: 0, width: 390, height: 844))
  }

  @Test("it never leaves the map, and is empty where the insets cover it whole")
  func held() {
    #expect(
      safeAreaBounds(PixelPadding(top: -10, right: -5, bottom: 0, left: 0), width: 200, height: 100)
        == ScreenRect(x: 0, y: 0, width: 200, height: 100))
    let covered = safeAreaBounds(
      PixelPadding(top: 80, right: 0, bottom: 80, left: 0), width: 200, height: 100)
    #expect(covered.y == 80 && covered.height == 0)
  }
}
