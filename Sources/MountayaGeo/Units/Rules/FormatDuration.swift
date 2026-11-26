/// formatDuration states a duration of `seconds` for the reader `units` describes, as the whole
/// hours and the minutes `splitDuration(_:)` splits it into, each with the language's narrow hour
/// and minute, joined by a space: 9,320 s is `2h 35m` in English. A whole number of hours drops the
/// minutes, `2h`, and a duration under an hour states its minutes alone, `1m`.
///
/// The empty string for a duration that is missing, zero, negative or no finite number, and for one
/// under thirty seconds, which rounds to no minute: printing a zero is a claim, not an absence.
/// Only the language of `units` is read.
public func formatDuration(_ seconds: Double?, units: UnitPreferences) -> String {
  guard let split = splitDuration(seconds) else { return "" }
  let patterns = unitPatterns(units.language)
  let minutes = formatMeasurement(
    Double(split.minutes), fractionDigits: 0, pattern: patterns.minute, language: units.language,
    patterns: patterns)
  if split.hours == 0 { return split.minutes == 0 ? "" : minutes }
  let hours = formatMeasurement(
    Double(split.hours), fractionDigits: 0, pattern: patterns.hour, language: units.language,
    patterns: patterns)
  return split.minutes == 0 ? hours : hours + " " + minutes
}
