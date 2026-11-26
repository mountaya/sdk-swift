import Testing

@testable import MountayaGeo

@Suite("zoomToAltitude")
struct ZoomToAltitudeTests {
  @Test("an altitude is the ground resolution across the camera's distance from the screen")
  func resolution() {
    #expect(zoomToAltitude(0, latitude: 0) == 93_925_820.3578125)
    #expect(isClose(zoomToAltitude(14, latitude: 0), 5_732.7771214485165, within: 1e-8))
    #expect(isClose(zoomToAltitude(14, latitude: 45.9), 3_989.5129588276745, within: 1e-8))
    #expect(isClose(zoomToAltitude(8, latitude: 60), 183_448.86788635256, within: 1e-6))
  }

  /// A clearance pass reads eye heights against terrain in meters, so no range holds the answer.
  @Test("the altitude is held to no range")
  func noRange() {
    #expect(
      isClose(
        zoomToAltitude(24, latitude: 45.9), zoomToAltitude(20, latitude: 45.9) / 16, within: 1e-12))
    #expect(zoomToAltitude(-2, latitude: 0) == zoomToAltitude(0, latitude: 0) * 4)
  }

  @Test("a shorter canvas is a lower altitude")
  func canvas() {
    #expect(
      isClose(
        zoomToAltitude(14, latitude: 45.9, viewportHeightPixels: 400),
        zoomToAltitude(14, latitude: 45.9) / 2, within: 1e-9))
    #expect(
      zoomToAltitude(14, latitude: 45.9, viewportHeightPixels: -400)
        == zoomToAltitude(14, latitude: 45.9))
  }

  @Test("a zoom that is no finite number is the safe mid altitude")
  func noZoom() {
    for zoom in [Double.nan, .infinity, -.infinity] {
      #expect(zoomToAltitude(zoom, latitude: 45.9) == 1_000, "for \(zoom)")
    }
    #expect(safeMidAltitudeMeters == 1_000)
  }

  @Test("a latitude that yields no altitude above zero is the safe mid altitude")
  func noLatitude() {
    #expect(zoomToAltitude(14, latitude: .nan) == 1_000)
    #expect(zoomToAltitude(14, latitude: 100) == 1_000)
    #expect(zoomToAltitude(-2_000, latitude: 0) == 1_000)
  }
}
