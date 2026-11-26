import Foundation
import MountayaClient

/// numberPlaceholder is what stands for the number in a unit pattern.
let numberPlaceholder = "{0}"

/// The digits a group holds, the first grouping separator standing after this many past the least.
private let groupDigits = 3

/// formatMeasurement is a value in the reader's `language`, rounded to `fractionDigits` places half
/// away from zero on its decimal value, written by the platform's locale services, and set in
/// `pattern` where it holds `numberPlaceholder`.
///
/// The rounding is done before the platform sees the value, so the figure is the same in every
/// SDK, and a value that rounds to zero is +0, stated with no sign. The number is grouped as
/// `patterns`, the language's row where none is given, says the language groups it: a language
/// whose minimum grouping digits are 2 writes no separator under 10,000, whatever minimum the
/// platform's own locale data holds. A figure stated to a fixed place keeps the
/// `minimumFractionDigits` it is asked for, so a distance to one decimal reads `1.0 km`.
func formatMeasurement(
  _ value: Double,
  fractionDigits: Int,
  pattern: String,
  language: String,
  patterns: UnitPatterns? = nil,
  minimumFractionDigits: Int = 0
) -> String {
  let row = patterns ?? unitPatterns(language)
  let rounded = roundHalfAwayFromZero(value, fractionDigits: fractionDigits)
  let grouping = abs(rounded) >= powerOfTen(groupDigits + row.minimumGroupingDigits - 1)
  let text = localeNumberText(
    rounded, languageTag: languageTagOf(language), fractionDigits: fractionDigits,
    grouping: grouping, minimumFractionDigits: minimumFractionDigits)
  return pattern.replacingOccurrences(of: numberPlaceholder, with: text)
}

/// isImperial tells whether a measurement system is the imperial one; any other system reads as
/// metric.
func isImperial(_ length: RestSchema.UnitLength) -> Bool {
  length == .imperial
}
