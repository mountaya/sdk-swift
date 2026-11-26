import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("watermarkFrame")
struct WatermarkFrameTests {
  @Test("the mark is measured from the top-left corner of the map's safe area")
  func safeArea() throws {
    let mark = try #require(watermarkOf(.failed, language: .en))
    #expect(
      watermarkFrame(mark, safeArea: PixelPadding(0))
        == ScreenRect(x: -4, y: -4, width: 180, height: mark.height))
    // A map drawn full bleed on a phone with a Dynamic Island, held in landscape.
    #expect(
      watermarkFrame(mark, safeArea: PixelPadding(top: 59, right: 0, bottom: 34, left: 47))
        == ScreenRect(x: 43, y: 55, width: 180, height: mark.height))
  }

  @Test("the frame's published extent is the mark's: 180 wide, 180 × 58 / 138 tall, inset -4")
  func extent() throws {
    let mark = try #require(watermarkOf(.noKey, language: .fr))
    #expect(watermarkWidth == 180 && mark.width == watermarkWidth)
    #expect(abs(watermarkHeight - 180 * 58 / 138) < 1e-9 && mark.height == watermarkHeight)
    #expect(watermarkInset == -4 && mark.x == watermarkInset && mark.y == watermarkInset)
    #expect(watermarkClearance == watermarkInset + watermarkHeight)
    #expect(
      watermarkFrame(mark, safeArea: PixelPadding(top: 59, right: 0, bottom: 34, left: 0)).maxY
        == 59 + watermarkClearance,
      "a host's view laid that far below the safe area's top clears it")
  }

  @Test("the frame a read holds before any mark is drawn is the mark's own")
  func heldBeforeTheMark() throws {
    let safeArea = PixelPadding(top: 59, right: 0, bottom: 34, left: 47)
    let mark = try #require(watermarkOf(.failed, language: .en))
    #expect(watermarkFrame(safeArea: safeArea) == watermarkFrame(mark, safeArea: safeArea))
    #expect(
      watermarkFrame(safeArea: PixelPadding(0))
        == ScreenRect(x: -4, y: -4, width: 180, height: watermarkHeight))
    #expect(
      watermarkFrame(safeArea: PixelPadding(top: -10, right: 0, bottom: 0, left: -10)).y == -4,
      "an inset below zero reads as none")
  }
}
