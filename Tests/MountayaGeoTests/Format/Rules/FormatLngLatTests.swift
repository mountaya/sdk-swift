import Testing

@testable import MountayaGeo

@Suite("formatLngLat")
struct FormatLngLatTests {
  @Test("the latitude comes first, each coordinate with its hemisphere")
  func latitudeFirst() {
    #expect(formatLngLat([6.8652, 45.9237]) == "45.9237\u{B0}N 6.8652\u{B0}E")
    #expect(formatLngLat([-0.1276, 51.5072]) == "51.5072\u{B0}N 0.1276\u{B0}W")
    #expect(formatLngLat([-77.0365, -12.0464]) == "12.0464\u{B0}S 77.0365\u{B0}W")
    #expect(formatLngLat([0, 0]) == "0.0000\u{B0}N 0.0000\u{B0}E")
  }

  @Test("a longitude past the antimeridian is the meridian it names")
  func pastTheAntimeridian() {
    #expect(formatLngLat([197.5, 45.9237]) == "45.9237\u{B0}N 162.5000\u{B0}W")
    #expect(formatLngLat([-190, -12.0464]) == "12.0464\u{B0}S 170.0000\u{B0}E")
  }

  /// Within the closed range a longitude is printed as written: 180 is east and -180 west.
  @Test("the antimeridian keeps the side it is written on")
  func antimeridianSide() {
    #expect(formatLngLat([180, 0]) == "0.0000\u{B0}N 180.0000\u{B0}E")
    #expect(formatLngLat([-180, 0]) == "0.0000\u{B0}N 180.0000\u{B0}W")
    #expect(formatLngLat([540, 0]) == "0.0000\u{B0}N 180.0000\u{B0}W")
  }

  @Test("a hemisphere is chosen after rounding")
  func afterRounding() {
    #expect(formatLngLat([-0.00004, 45]) == "45.0000\u{B0}N 0.0000\u{B0}E")
    #expect(formatLngLat([6, -0.00001]) == "0.0000\u{B0}N 6.0000\u{B0}E")
    #expect(formatLngLat([-0.00005, -0.00005]) == "0.0001\u{B0}S 0.0001\u{B0}W")
    #expect(formatLngLat([-0.0, -0.0]) == "0.0000\u{B0}N 0.0000\u{B0}E")
  }

  @Test("an altitude is not printed")
  func altitude() {
    #expect(formatLngLat([6.8652, 45.9237, 1035]) == "45.9237\u{B0}N 6.8652\u{B0}E")
  }

  /// A latitude has no wrap of its own: past a pole is printed as written.
  @Test("a latitude is printed as written")
  func latitudeAsWritten() {
    #expect(formatLngLat([10, 95]) == "95.0000\u{B0}N 10.0000\u{B0}E")
  }

  @Test("a position that names no place prints nothing")
  func noPlace() {
    #expect(formatLngLat([]) == nil)
    #expect(formatLngLat([6.88]) == nil)
    #expect(formatLngLat([.nan, 45]) == nil)
    #expect(formatLngLat([6, -.infinity]) == nil)
  }
}
