import MountayaElements
import MountayaGeo
import Testing

@Suite("CameraFit")
struct CameraFitTests {
  @Test(
    "a fit stating nothing frames with no padding, the window's ceiling and the renderer's pace")
  func defaults() {
    let fit = CameraFit()
    #expect(fit.padding == nil && fit.maxZoom == nil && fit.duration == nil)
  }

  @Test("two fits are equal where they state the same members, each the same number")
  func equality() {
    #expect(CameraFit(maxZoom: .nan) == CameraFit(maxZoom: .nan))
    #expect(CameraFit(maxZoom: 15) != CameraFit())
    #expect(CameraFit(padding: PixelPadding(0)) != CameraFit(), "a padding of 0 is stated")
    #expect(CameraFit(padding: PixelPadding(48)) == CameraFit(padding: PixelPadding(48)))
    #expect(CameraFit(duration: .zero) != CameraFit(duration: .milliseconds(1)))
  }
}
