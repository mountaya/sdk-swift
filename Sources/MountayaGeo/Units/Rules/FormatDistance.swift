import MountayaClient

/// The places a distance is stated to.
private let distanceFractionDigits = 1

/// formatDistance states a distance of `meters` for the reader `units` describes, in kilometers or
/// in miles as its `length` asks, to one decimal: 850 m is `0.9 km` and `0.5 mi` in English, and
/// 24,300 m is `24.3 km`. One decimal, because an itinerary's length is a planning figure.
///
/// The number is rounded half away from zero on its decimal value, written with the reader's digits
/// and decimal mark, and set in the language's own pattern. The empty string for a distance that is
/// missing or no finite number, so a caller renders the answer as it is.
public func formatDistance(_ meters: Double?, units: UnitPreferences) -> String {
  guard let meters, meters.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  if isImperial(units.length) {
    return formatMeasurement(
      convertLength(meters, from: .meter, to: .mile), fractionDigits: distanceFractionDigits,
      pattern: patterns.mile, language: units.language, patterns: patterns)
  }
  return formatMeasurement(
    convertLength(meters, from: .meter, to: .kilometer), fractionDigits: distanceFractionDigits,
    pattern: patterns.kilometer, language: units.language, patterns: patterns)
}
