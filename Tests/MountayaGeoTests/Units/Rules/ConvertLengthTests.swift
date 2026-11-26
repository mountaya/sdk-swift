import Testing

@testable import MountayaGeo

@Suite("convertLength")
struct ConvertLengthTests {
  /// Through the exact defining values, a mile is 5,280 feet exactly, never 5,280.0002.
  @Test("a mile is exactly 5,280 feet")
  func mile() {
    #expect(convertLength(1, from: .mile, to: .foot) == 5_280)
    #expect(convertLength(1, from: .mile, to: .meter) == 1_609.344)
    #expect(convertLength(1, from: .foot, to: .meter) == 0.3048)
    #expect(convertLength(1, from: .inch, to: .centimeter) == 2.54)
    #expect(convertLength(1, from: .foot, to: .inch) == 12)
  }

  @Test("a length in its own unit is returned as it is")
  func ownUnit() {
    for unit in LengthUnit.allCases {
      #expect(convertLength(0.1, from: unit, to: unit) == 0.1)
    }
  }

  @Test("a kilometer and a mile convert both ways")
  func bothWays() {
    #expect(isClose(convertLength(1.609344, from: .kilometer, to: .mile), 1, within: 1e-15))
    #expect(convertLength(1, from: .mile, to: .kilometer) == 1.609344)
  }

  @Test("nothing is clamped and no value is refused")
  func nothingClamped() {
    #expect(convertLength(-10, from: .foot, to: .meter) == -3.048)
    #expect(convertLength(-.infinity, from: .mile, to: .foot) == -.infinity)
    #expect(convertLength(.nan, from: .meter, to: .inch).isNaN)
  }
}
