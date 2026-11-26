import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("MapWatermark")
struct MapWatermarkTests {
  @Test("two marks are equal where they hold the same frame, link and label")
  func equality() {
    let mark = MapWatermark(
      drawing: "watermark", x: -4, y: -4, width: 180, height: 75, href: watermarkRoot,
      label: watermarkLabelWord)
    #expect(mark == mark)
    #expect(
      mark
        != MapWatermark(
          drawing: "watermark", x: -4, y: -4, width: 180, height: 75,
          href: "https://www.mountaya.com/fr/", label: watermarkLabelWord))
  }
}
