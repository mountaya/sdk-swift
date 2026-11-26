import Testing

@testable import MountayaGeo

@Suite("convertSpeed")
struct ConvertSpeedTests {
  @Test("a rate converts to a rate by the ratio of its parts")
  func rateToRate() {
    #expect(convertSpeed(36, from: .kilometerPerHour, to: .meterPerSecond) == 10)
    #expect(convertSpeed(1, from: .milePerHour, to: .kilometerPerHour) == 1.609344)
  }

  /// A pace is the reciprocal of a rate, in decimal minutes.
  @Test("a rate converts to a pace as its reciprocal in decimal minutes")
  func rateToPace() {
    #expect(
      convertSpeed(4.5, from: .kilometerPerHour, to: .minutePerKilometer) == 13.333333333333334)
    #expect(
      isClose(
        convertSpeed(4.5, from: .kilometerPerHour, to: .minutePerMile), 21.45792, within: 1e-12))
    #expect(
      convertSpeed(13.333333333333334, from: .minutePerKilometer, to: .kilometerPerHour) == 4.5)
  }

  @Test("a pace converts to a pace by the ratio of its parts")
  func paceToPace() {
    #expect(convertSpeed(1, from: .minutePerKilometer, to: .minutePerMile) == 1.609344)
  }

  /// The division answers what it answers: no rate is refused.
  @Test("a rate of zero is a pace of infinity, and a pace of zero a rate of infinity")
  func zeros() {
    #expect(convertSpeed(0, from: .kilometerPerHour, to: .minutePerKilometer) == .infinity)
    #expect(convertSpeed(0, from: .minutePerMile, to: .milePerHour) == .infinity)
    #expect(convertSpeed(-0.0, from: .kilometerPerHour, to: .minutePerKilometer) == -.infinity)
    #expect(convertSpeed(.infinity, from: .kilometerPerHour, to: .minutePerKilometer) == 0)
  }

  @Test("a speed in its own unit is returned as it is")
  func ownUnit() {
    for unit in SpeedUnit.allCases {
      #expect(convertSpeed(0.1, from: unit, to: unit) == 0.1)
    }
  }

  @Test("the two minute units are the paces")
  func paces() {
    #expect(SpeedUnit.allCases.filter(\.isPace) == [.minutePerKilometer, .minutePerMile])
  }
}
