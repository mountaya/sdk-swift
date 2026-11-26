import Foundation
import MountayaClient

/// The places a rate is stated to.
private let rateFractionDigits = 1

/// formatSpeed states a travel rate of `kmh`, kilometers per hour as the wire carries every rate,
/// for the reader `units` describes: its `length` picks the system and its `pace` the form. Per
/// time, it is a rate to one decimal, `4.5 km/h`, or `2,8 mi/h` for a French reader of miles. Per
/// distance, it is the reciprocal as the pace clock `formatPaceClock(_:)` writes it, the seconds
/// rounded before the split, `13:20 min/km` or `21:27 min/mi`, its digits Latin in every language.
///
/// A rate that rounds to zero is stated with no sign, `0 km/h`. The empty string for a rate that is
/// missing or no finite number, and per distance for one of zero or less, which has no reciprocal a
/// reader can read. A pace form other than per distance reads as per time.
public func formatSpeed(_ kmh: Double?, units: UnitPreferences) -> String {
  guard let kmh, kmh.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  let imperial = isImperial(units.length)
  if units.pace == .perDistance {
    if kmh <= 0 { return "" }
    let clock = formatPaceClock(
      convertSpeed(
        kmh, from: .kilometerPerHour, to: imperial ? .minutePerMile : .minutePerKilometer))
    if clock.isEmpty { return "" }
    return (imperial ? patterns.minutePerMile : patterns.minutePerKilometer)
      .replacingOccurrences(of: numberPlaceholder, with: clock)
  }
  if imperial {
    return formatMeasurement(
      convertSpeed(kmh, from: .kilometerPerHour, to: .milePerHour),
      fractionDigits: rateFractionDigits, pattern: patterns.milePerHour,
      language: units.language, patterns: patterns)
  }
  return formatMeasurement(
    kmh, fractionDigits: rateFractionDigits, pattern: patterns.kilometerPerHour,
    language: units.language, patterns: patterns)
}
