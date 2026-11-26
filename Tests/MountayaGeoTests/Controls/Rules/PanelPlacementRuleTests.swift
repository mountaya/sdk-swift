import Testing

@testable import MountayaGeo

@Suite("panelPlacement")
struct PanelPlacementRuleTests {
  /// mark is the watermark's frame on a map whose safe area starts 59 points down.
  private let mark = ScreenRect(x: -4, y: 55, width: 180, height: 75.5)
  /// tablet is a map with no inset, as wide as a tablet held across.
  private let tablet = ScreenRect(x: 0, y: 0, width: 1004, height: 700)
  /// phone is a phone's map drawn full bleed, its safe area under the status bar and above the
  /// home indicator.
  private let phone = ScreenRect(x: 0, y: 59, width: 390, height: 751)

  @Test("a toggle on the right opens its panel to its left, level with it, laid out from its top")
  func right() {
    let toggle = ScreenRect(x: 950, y: 120, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: tablet, panelHeight: nil, clearOf: mark)
    #expect(placed.x == 950 - 8 - 340 && placed.y == 120 && placed.width == 340)
    #expect(placed.layout == panelLayout(mapWidth: 1004, mapHeight: 700, topInset: 120))
  }

  @Test("a toggle on the left opens its panel to its right")
  func left() {
    let toggle = ScreenRect(x: 10, y: 160, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: tablet, panelHeight: nil, clearOf: mark)
    #expect(placed.x == 62 && placed.y == 160)
  }

  @Test("a narrow safe area's panel fills its width less the inset on each side, inside it")
  func narrow() {
    let toggle = ScreenRect(x: 336, y: 140, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: phone, panelHeight: nil, clearOf: nil)
    #expect(placed.x == 10 && placed.width == 370 && placed.y == 140)
    #expect(placed.layout.fill)
    #expect(placed.layout.maxHeight == 751 - (140 - 59) - 16, "no lower than the safe area")
  }

  @Test("a panel is held inside the safe area, never under the status bar or past a cutout")
  func inside() {
    let landscape = ScreenRect(x: 59, y: 0, width: 726, height: 369)
    let toggle = ScreenRect(x: 720, y: 10, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: landscape, panelHeight: 300, clearOf: nil)
    #expect(placed.x >= landscape.x && placed.x + placed.width <= landscape.maxX)
    let high = panelPlacement(
      beside: ScreenRect(x: 336, y: 20, width: 44, height: 44), within: phone, panelHeight: 300,
      clearOf: nil)
    #expect(high.y == 59, "a toggle drawn under the status bar opens its panel below it")
  }

  @Test("a panel that would lay over the watermark moves clear of it, laid out from there")
  func clearOfTheMark() {
    let toggle = ScreenRect(x: 336, y: 68, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: phone, panelHeight: 300, clearOf: mark)
    #expect(placed.y == mark.maxY)
    #expect(
      placed.layout == panelLayout(mapWidth: 390, mapHeight: 751, topInset: mark.maxY - 59))
    let white = panelPlacement(beside: toggle, within: phone, panelHeight: 300, clearOf: nil)
    #expect(white.y == 68, "with no mark it stands level with its toggle")
  }

  @Test("a panel moves below the frame and never to its right, even where that move is longer")
  func belowTheMark() {
    let toggle = ScreenRect(x: 100, y: 64, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: tablet, panelHeight: 300, clearOf: mark)
    #expect(placed.x == 152, "beside its toggle, where it opened")
    #expect(placed.y == mark.maxY, "66.5 down rather than 24 right")
    #expect(
      placed.layout == panelLayout(mapWidth: 1004, mapHeight: 700, topInset: mark.maxY),
      "laid out in the room under the frame")
  }

  @Test("on a short safe area a panel under the frame is held to the room left there")
  func heldUnderTheMark() {
    let short = ScreenRect(x: 0, y: 59, width: 1004, height: 200)
    let toggle = ScreenRect(x: 10, y: 140, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: short, panelHeight: 300, clearOf: mark)
    #expect(placed.x == 62 && placed.y == mark.maxY, "below the frame, never beside it")
    #expect(placed.layout.maxHeight == 259 - mark.maxY, "its height the room under the frame")
  }

  @Test("a toggle in the lower half raises its panel so its bottom stays inside the safe area")
  func lower() {
    let toggle = ScreenRect(x: 950, y: 600, width: 44, height: 44)
    let placed = panelPlacement(beside: toggle, within: tablet, panelHeight: 300, clearOf: mark)
    #expect(placed.y == 400)
    #expect(placed.layout.maxHeight == 700)
    let first = panelPlacement(beside: toggle, within: tablet, panelHeight: nil, clearOf: mark)
    #expect(first.y == 600, "before it is laid out, level with its toggle")
  }
}
