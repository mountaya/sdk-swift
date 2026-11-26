import Testing

@testable import MountayaGeo

@Suite("wrapLongitude")
struct WrapLongitudeTests {
  @Test("a longitude is brought into the range by whole turns")
  func wholeTurns() {
    #expect(wrapLongitude(190) == -170)
    #expect(wrapLongitude(-190) == 170)
    #expect(wrapLongitude(906.5) == -173.5)
    #expect(wrapLongitude(6.5) == 6.5)
  }

  /// The range is [-180, 180): the antimeridian is written -180 whichever side it came from.
  @Test("the antimeridian is written -180")
  func antimeridian() {
    #expect(wrapLongitude(180) == -180)
    #expect(wrapLongitude(-180) == -180)
    #expect(wrapLongitude(540) == -180)
  }

  /// The second remainder is what keeps a hair under -180 in the range: a turn added to it rounds
  /// to a whole turn, and a whole turn's remainder is zero.
  @Test("a longitude a hair under the range lands on its west edge")
  func hairUnder() {
    #expect(wrapLongitude(-180.00000000000003) == -180)
    #expect(isClose(wrapLongitude(-180.0000000001), 179.9999999999, within: 1e-9))
  }

  @Test("a longitude that is not finite names no meridian")
  func notFinite() {
    #expect(wrapLongitude(.nan).isNaN)
    #expect(wrapLongitude(.infinity).isNaN)
    #expect(wrapLongitude(-.infinity).isNaN)
  }

  @Test("the limit is the antimeridian")
  func limit() {
    #expect(longitudeLimit == 180)
  }
}
