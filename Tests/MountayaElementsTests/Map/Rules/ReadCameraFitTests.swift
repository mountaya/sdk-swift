import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("readCameraFit")
struct ReadCameraFitTests {
  @Test("a fit is answered as stated, zeros and a ceiling past the window included")
  func taken() throws {
    for fit in [
      CameraFit(), CameraFit(padding: PixelPadding(48), duration: .zero),
      CameraFit(padding: PixelPadding(top: 24, right: 24, bottom: 120, left: 24), maxZoom: 15),
      CameraFit(padding: PixelPadding(0), duration: .zero), CameraFit(maxZoom: 25),
    ] {
      #expect(try readCameraFit(fit) == fit)
    }
  }

  @Test("a ceiling that is no finite number, a negative duration or padding are refused by name")
  func refused() {
    #expect(throws: MapError(kind: .numberRefused, name: "maxZoom")) {
      try readCameraFit(CameraFit(maxZoom: .nan, duration: .milliseconds(-1)))
    }
    #expect(throws: MapError(kind: .numberRefused, name: "duration")) {
      try readCameraFit(CameraFit(padding: PixelPadding(-1), duration: .milliseconds(-250)))
    }
    for padding in [
      PixelPadding(-1), PixelPadding(top: 0, right: 0, bottom: .nan, left: 0),
      PixelPadding(top: .infinity, right: 0, bottom: 0, left: 0),
    ] {
      #expect(throws: MapError(kind: .numberRefused, name: "padding")) {
        try readCameraFit(CameraFit(padding: padding))
      }
    }
  }
}
