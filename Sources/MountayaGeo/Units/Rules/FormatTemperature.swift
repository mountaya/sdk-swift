import MountayaClient

/// formatTemperature states a temperature of `celsius`, degrees Celsius, for the reader `units`
/// describes, in the scale its `temperature` asks, to the whole degree: 4 °C is `4°C`, or `39°F`.
/// It reads `temperature` alone and never `length`, so an imperial reader who stored Celsius is
/// shown Celsius, `4 °C` for a French one.
///
/// A temperature that rounds to zero is stated with no sign, `0°C`. The empty string for a
/// temperature that is missing or no finite number. Any scale other than Fahrenheit reads as
/// Celsius.
public func formatTemperature(_ celsius: Double?, units: UnitPreferences) -> String {
  guard let celsius, celsius.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  if units.temperature == .fahrenheit {
    return formatMeasurement(
      convertTemperature(celsius, from: .celsius, to: .fahrenheit), fractionDigits: 0,
      pattern: patterns.fahrenheit, language: units.language, patterns: patterns)
  }
  return formatMeasurement(
    celsius, fractionDigits: 0, pattern: patterns.celsius, language: units.language,
    patterns: patterns)
}
