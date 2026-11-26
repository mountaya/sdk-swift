/// fahrenheitOffset is the Fahrenheit reading of the Celsius zero.
private let fahrenheitOffset: Double = 32

/// convertTemperature converts a value from one temperature scale to the other: a Fahrenheit
/// reading is nine fifths of the Celsius one plus 32, computed as a product by nine and a
/// quotient by five rather than through a rounded 1.8, so 37 C is exactly 98.6 F and back. A
/// value on its own scale is returned as it is.
public func convertTemperature(
  _ value: Double, from: TemperatureUnit, to: TemperatureUnit
) -> Double {
  if from == to { return value }
  if to == .fahrenheit { return value * 9 / 5 + fahrenheitOffset }
  return (value - fahrenheitOffset) * 5 / 9
}
