import Testing

@testable import MountayaGeo

@Suite("altitudeToZoom")
struct AltitudeToZoomTests {
  @Test("the same altitude is another zoom at another latitude")
  func latitude() {
    #expect(isClose(altitudeToZoom(1_500, latitude: 0), 15.934271690397807, within: 1e-12))
    #expect(isClose(altitudeToZoom(1_500, latitude: 45.9), 15.411250131748451, within: 1e-12))
    #expect(isClose(altitudeToZoom(1_500, latitude: 60), 14.934271690397807, within: 1e-12))
    // Eight times as high is three zooms out.
    #expect(isClose(altitudeToZoom(12_000, latitude: 45.9), 12.411250131748451, within: 1e-12))
  }

  @Test("the zoom is held within the zooms a flight is framed at")
  func held() {
    #expect(altitudeToZoom(400, latitude: 45.9) == 16)
    #expect(altitudeToZoom(1, latitude: 45.9) == 16)
    #expect(altitudeToZoom(100_000_000, latitude: 0) == 4)
    #expect(altitudeZoomCeiling == 16)
    #expect(altitudeZoomFloor == 4)
  }

  /// A canvas twice as tall puts the camera twice as far from the screen: twice the altitude shows
  /// the ground at the zoom the nominal canvas shows it at, where on that canvas it is a zoom out.
  @Test("a taller canvas is a closer zoom")
  func canvas() {
    let nominal = altitudeToZoom(1_500, latitude: 45.9)
    #expect(
      isClose(
        altitudeToZoom(3_000, latitude: 45.9, viewportHeightPixels: 1_600), nominal, within: 1e-12))
    #expect(isClose(altitudeToZoom(3_000, latitude: 45.9), nominal - 1, within: 1e-12))
    #expect(altitudeToZoom(1_500, latitude: 45.9, viewportHeightPixels: 800) == nominal)
    #expect(altitudeToZoom(1_500, latitude: 45.9, viewportHeightPixels: .nan) == nominal)
    #expect(altitudeToZoom(1_500, latitude: 45.9, viewportHeightPixels: 0) == nominal)
  }

  @Test("an altitude that is no finite number above zero is the safe mid zoom")
  func noAltitude() {
    for altitude in [0, -0.0, -5, .nan, .infinity, -.infinity] {
      #expect(altitudeToZoom(altitude, latitude: 45.9) == 12, "for \(altitude)")
    }
    #expect(safeMidZoom == 12)
  }

  @Test("a latitude that yields no zoom is the safe mid zoom")
  func noLatitude() {
    #expect(altitudeToZoom(1_500, latitude: .nan) == 12)
    #expect(altitudeToZoom(1_500, latitude: 100) == 12)
  }

  @Test("an altitude and its zoom round trip")
  func roundTrip() {
    #expect(
      isClose(
        zoomToAltitude(altitudeToZoom(1_500, latitude: 45.9), latitude: 45.9), 1_500, within: 1e-9))
    #expect(
      isClose(altitudeToZoom(zoomToAltitude(14, latitude: 45.9), latitude: 45.9), 14, within: 1e-12)
    )
  }
}
