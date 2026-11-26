import Testing

@testable import MountayaGeo

@Suite("groundMetersPerPixel")
struct GroundMetersPerPixelTests {
  /// At zoom 0 on the equator one pixel spans the circumference over one 512-pixel tile.
  @Test("at zoom 0 on the equator a pixel is the circumference over one tile")
  func zoomZero() {
    #expect(groundMetersPerPixel(zoom: 0, latitude: 0) == 78_271.51696484375)
    #expect(
      groundMetersPerPixel(zoom: 0, latitude: 0)
        == webMercatorCircumferenceMeters / webMercatorTileSizePixels)
    #expect(webMercatorCircumferenceMeters == 40_075_016.686)
    #expect(webMercatorTileSizePixels == 512)
    #expect(webMercatorMaxLatitude == 85.051129)
  }

  @Test("each zoom halves the pixel, and the latitude shrinks it by its cosine")
  func zoomAndLatitude() {
    #expect(groundMetersPerPixel(zoom: 1, latitude: 0) == 39_135.758482421875)
    #expect(
      isClose(groundMetersPerPixel(zoom: 14, latitude: 45.9), 3.3245941323563954, within: 1e-12))
    #expect(isClose(groundMetersPerPixel(zoom: 8, latitude: 60), 152.87405657196047, within: 1e-9))
    #expect(
      groundMetersPerPixel(zoom: 8, latitude: 60) == groundMetersPerPixel(zoom: 8, latitude: -60))
  }

  @Test("a zoom that is no finite number spans no ground")
  func noZoom() {
    #expect(groundMetersPerPixel(zoom: .nan, latitude: 45.9) == 0)
    #expect(groundMetersPerPixel(zoom: .infinity, latitude: 45.9) == 0)
    #expect(groundMetersPerPixel(zoom: -.infinity, latitude: 45.9) == 0)
  }

  /// The latitude is read as written: a caller that needs a positive resolution holds it first.
  @Test("a latitude is read as written")
  func latitudeAsWritten() {
    #expect(groundMetersPerPixel(zoom: 0, latitude: 120) < 0)
    #expect(groundMetersPerPixel(zoom: 0, latitude: .nan).isNaN)
  }

  @Test("a degree of the projection is its circumference over a turn")
  func degree() {
    #expect(isClose(metersPerDegreeWebMercator, 111_319.49079444444, within: 1e-9))
  }
}
