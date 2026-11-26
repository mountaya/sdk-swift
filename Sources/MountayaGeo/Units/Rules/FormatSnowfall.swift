import MountayaClient

/// formatSnowfall states a depth of snow of `centimeters` for the reader `units` describes, as its
/// `length` asks: in the metric system to the whole centimeter, 35 cm being `35 cm`, and in the
/// imperial to one decimal of an inch, 2.54 centimeters to the inch, its trailing zero dropped,
/// 35 cm being `13.8 in` and 25.4 cm `10 in`. It reads `length` alone.
///
/// The number is rounded half away from zero on its decimal value, and one that rounds to zero is
/// stated with no sign. The empty string for a depth that is missing or no finite number.
public func formatSnowfall(_ centimeters: Double?, units: UnitPreferences) -> String {
  guard let centimeters, centimeters.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  if isImperial(units.length) {
    return formatMeasurement(
      convertLength(centimeters, from: .centimeter, to: .inch), fractionDigits: 1,
      pattern: patterns.inch, language: units.language, patterns: patterns)
  }
  return formatMeasurement(
    centimeters, fractionDigits: 0, pattern: patterns.centimeter, language: units.language,
    patterns: patterns)
}
