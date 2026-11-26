import Foundation
import MountayaClient

/// The placeholder of a range pattern's second number.
private let secondNumberPlaceholder = "{1}"

/// formatAltitudeRange states an altitude band, its lowest and highest altitude in meters, as one
/// range in the reader's elevation unit, meters or feet as `units.length` asks, each bound whole
/// (`geo.format.altitude-range`): `1,035–1,850 m` in English and `1 035–1 850 m` in French, the
/// bounds in the order given.
///
/// The range is the language's own, never two figures joined by hand: the separator and the
/// approximation are its range patterns (`rangePatterns(_:)`), the numbers its digits and grouping,
/// written as `formatElevation(_:units:)` writes each, and the unit is stated once, after the
/// range. Two bounds written alike read as that figure, approximately, `~1,000 m`, a bound that
/// rounds to zero read as zero whatever its sign; and a band whose first bound is below zero takes
/// a space either side of the separator, so the sign stands apart from it, as the locale services
/// write it. The empty string where either bound is missing or no finite number, so a caller
/// renders the answer as it is.
public func formatAltitudeRange(min: Double?, max: Double?, units: UnitPreferences) -> String {
  guard let min, let max, min.isFinite, max.isFinite else { return "" }
  let patterns = unitPatterns(units.language)
  let imperial = isImperial(units.length)
  let wholes = [min, max].map { meters in
    roundHalfAwayFromZero(
      imperial ? convertLength(meters, from: .meter, to: .foot) : meters, fractionDigits: 0)
  }
  let bounds = wholes.map {
    formatMeasurement(
      $0, fractionDigits: 0, pattern: numberPlaceholder, language: units.language,
      patterns: patterns)
  }
  let range = rangePatterns(units.language)
  let text: String
  if sameText(bounds[0], bounds[1]) {
    text = range.approximately.replacingOccurrences(of: numberPlaceholder, with: bounds[0])
  } else {
    text = (wholes[0] < 0 ? spaced(range.range) : range.range)
      .replacingOccurrences(of: numberPlaceholder, with: bounds[0])
      .replacingOccurrences(of: secondNumberPlaceholder, with: bounds[1])
  }
  return (imperial ? patterns.foot : patterns.meter)
    .replacingOccurrences(of: numberPlaceholder, with: text)
}

/// A range pattern with a space either side of its separator, where it has none there.
private func spaced(_ pattern: String) -> String {
  guard let first = pattern.range(of: numberPlaceholder),
    let second = pattern.range(of: secondNumberPlaceholder), first.upperBound <= second.lowerBound
  else { return pattern }
  var separator = String(pattern[first.upperBound..<second.lowerBound])
  if separator.unicodeScalars.first.map(isWhiteSpace) != true { separator = " " + separator }
  if separator.unicodeScalars.last.map(isWhiteSpace) != true { separator += " " }
  return String(pattern[..<first.upperBound]) + separator + String(pattern[second.lowerBound...])
}
