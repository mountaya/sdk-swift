import Testing

@testable import MountayaGeo

@Suite("cameraDistancePixels")
struct CameraDistancePixelsTests {
  @Test("the camera stands one and a half canvas heights from the screen")
  func oneAndAHalf() {
    #expect(cameraDistancePixels(800) == 1_200)
    #expect(cameraDistancePixels(1_080) == 1_620)
    #expect(defaultViewportHeightPixels == 800)
    #expect(fieldOfViewDistanceFactor == 1.5)
  }

  @Test("a height that is no canvas reads the nominal one")
  func noCanvas() {
    for height in [0, -1, -0.0, .nan, .infinity] {
      #expect(cameraDistancePixels(height) == 1_200, "for \(height)")
    }
  }
}
