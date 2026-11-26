import Testing

@testable import MountayaGeo

@Suite("convertTemperature")
struct ConvertTemperatureTests {
  @Test("a Fahrenheit reading is nine fifths of the Celsius one plus 32")
  func nineFifths() {
    #expect(convertTemperature(0, from: .celsius, to: .fahrenheit) == 32)
    #expect(convertTemperature(100, from: .celsius, to: .fahrenheit) == 212)
    #expect(convertTemperature(-40, from: .celsius, to: .fahrenheit) == -40)
    #expect(convertTemperature(-40, from: .fahrenheit, to: .celsius) == -40)
  }

  /// Nine and five rather than a rounded 1.8, so a whole Celsius reading lands on its exact figure.
  @Test("a whole Celsius reading converts exactly, and back")
  func exact() {
    #expect(convertTemperature(37, from: .celsius, to: .fahrenheit) == 98.6)
    #expect(convertTemperature(98.6, from: .fahrenheit, to: .celsius) == 37)
  }

  @Test("a reading on its own scale is returned as it is")
  func ownScale() {
    for unit in TemperatureUnit.allCases {
      #expect(convertTemperature(0.1, from: unit, to: unit) == 0.1)
    }
  }
}
