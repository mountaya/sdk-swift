import MountayaClient

/// formatHumidity states a relative humidity of `percent` for the reader `units` describes, to the
/// whole percent in the language's own pattern, whatever its preferences: 54.6 is `55%` in
/// English and `55 %` in French, behind a no-break space.
///
/// The number is rounded half away from zero on its decimal value, and one that rounds to zero is
/// stated with no sign, `0%`. The empty string for a humidity that is missing or no finite number.
public func formatHumidity(_ percent: Double?, units: UnitPreferences) -> String {
  guard let percent, percent.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  return formatMeasurement(
    percent, fractionDigits: 0, pattern: patterns.percent, language: units.language,
    patterns: patterns)
}
