import Testing

@testable import MountayaGeo

@Suite("convertAngle")
struct ConvertAngleTests {
  @Test("an angle converts through pi over 180, by a product with the precomputed factor")
  func throughPi() {
    #expect(convertAngle(180, from: .degree, to: .radian) == .pi)
    #expect(convertAngle(1, from: .radian, to: .degree) == 57.29577951308232)
    #expect(convertAngle(1, from: .degree, to: .radian) == 0.017453292519943295)
  }

  /// An angle is not reduced to one turn: 720 degrees is four pi.
  @Test("nothing is reduced to one turn")
  func noTurnReduced() {
    #expect(isClose(convertAngle(720, from: .degree, to: .radian), 4 * .pi, within: 1e-15))
    #expect(convertAngle(-.pi / 2, from: .radian, to: .degree) == -90)
  }

  @Test("the declared constants are the fixtures' own")
  func constants() {
    #expect(radiansPerDegree == 0.017453292519943295)
    #expect(degreesPerRadian == 57.29577951308232)
    #expect(degreesPerTurn == 360)
  }

  @Test("an angle in its own unit is returned as it is")
  func ownUnit() {
    for unit in AngleUnit.allCases {
      #expect(convertAngle(0.1, from: unit, to: unit) == 0.1)
    }
  }
}
