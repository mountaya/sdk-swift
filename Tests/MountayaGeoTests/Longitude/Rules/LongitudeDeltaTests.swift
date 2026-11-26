import Testing

@testable import MountayaGeo

@Suite("longitudeDelta")
struct LongitudeDeltaTests {
  @Test("the way across the antimeridian is the short one")
  func shortWay() {
    #expect(longitudeDelta(from: 179.9, to: -179.9) == 0.19999999999998863)
    #expect(longitudeDelta(from: -179.9, to: 179.9) == -0.20000000000004547)
  }

  @Test("a difference already the short way is the plain difference")
  func plain() {
    #expect(longitudeDelta(from: 6.8652, to: 7.2) == 7.2 - 6.8652)
  }

  /// Exactly half a turn keeps its sign as the plain difference has it, either way.
  @Test("half a turn is kept as the plain difference")
  func halfATurn() {
    #expect(longitudeDelta(from: 0, to: 180) == 180)
    #expect(longitudeDelta(from: 0, to: -180) == -180)
    #expect(longitudeDelta(from: -90, to: 90) == 180)
  }

  @Test("the long way round is turned")
  func longWay() {
    #expect(longitudeDelta(from: 10, to: 280) == -90)
    #expect(longitudeDelta(from: 190, to: -170) == 0)
  }

  @Test("a longitude that is not finite answers NaN")
  func notFinite() {
    #expect(longitudeDelta(from: .nan, to: 10).isNaN)
    #expect(longitudeDelta(from: 0, to: .infinity).isNaN)
  }
}
