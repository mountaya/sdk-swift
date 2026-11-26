import MountayaClient

/// formatElevation states an elevation or a height gain of `meters` for the reader `units`
/// describes, in meters or in feet as its `length` asks, to the whole unit: 1,531 m is `1,531 m`
/// and `5,023 ft` in English. Whole numbers, because a terrain sample is not accurate to a
/// decimeter.
///
/// The number is rounded half away from zero on its decimal value, and one that rounds to zero is
/// stated with no sign, `0 m`. The empty string for a value that is missing or no finite number.
public func formatElevation(_ meters: Double?, units: UnitPreferences) -> String {
  guard let meters, meters.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  if isImperial(units.length) {
    return formatMeasurement(
      convertLength(meters, from: .meter, to: .foot), fractionDigits: 0, pattern: patterns.foot,
      language: units.language, patterns: patterns)
  }
  return formatMeasurement(
    meters, fractionDigits: 0, pattern: patterns.meter, language: units.language,
    patterns: patterns)
}
