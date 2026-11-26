import MountayaClient

/// formatDistanceTick states a stop of a distance axis for the reader `units` describes
/// (`distanceTicks(from:to:length:target:)`): its value in kilometers or miles, as `units.length`
/// asks, with the fraction digits the stop needs, kept even where they are zeros, so neighbouring
/// stops read as different numbers, `0.5 km` beside `1.0 km`, and a whole step reads whole,
/// `5 km`. The number is written by the locale services and set in the language's own pattern.
public func formatDistanceTick(_ tick: DistanceTick, units: UnitPreferences) -> String {
  let patterns = unitPatterns(units.language)
  return formatMeasurement(
    tick.value, fractionDigits: tick.fractionDigits,
    pattern: isImperial(units.length) ? patterns.mile : patterns.kilometer,
    language: units.language, patterns: patterns, minimumFractionDigits: tick.fractionDigits)
}
