import MountayaClient

/// An angle's pattern: the degree sign follows the number in every language.
private let degreesPattern = "{0}°"

/// formatSlope states a slope of `degrees` for the reader `units` describes, as an angle or as a
/// percentage grade as its `slope` asks, to the whole unit: 12.5° is `13°`, or `22%` as a grade.
/// A grade is `tan(θ) × 100`, never θ, so 45° is `100%`.
///
/// A descent keeps its sign, `-22%`, and a slope that rounds to zero is level to the precision
/// stated and takes none, `0°`. The degree sign is the same in every language; a percentage takes
/// the language's own pattern. The empty string for a slope that is missing or no finite number.
/// Any slope unit other than a percentage reads as degrees.
public func formatSlope(_ degrees: Double?, units: UnitPreferences) -> String {
  guard let degrees, degrees.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  if units.slope == .percentage {
    return formatMeasurement(
      convertSlope(degrees, from: .degrees, to: .percentage), fractionDigits: 0,
      pattern: patterns.percent, language: units.language, patterns: patterns)
  }
  return formatMeasurement(
    degrees, fractionDigits: 0, pattern: degreesPattern, language: units.language,
    patterns: patterns)
}
