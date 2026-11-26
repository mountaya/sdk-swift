import Foundation

/// localeNumberText is a value written by the platform's locale services for `languageTag`: its
/// digits, its decimal mark, its minus sign and, where `grouping` asks for them, its grouping
/// separators, with no fraction digit past `fractionDigits` and none it does not need, but the
/// `minimumFractionDigits` it is asked to keep, held within `0...fractionDigits`: a figure stated
/// to a fixed place keeps its zero, so 1 to one place is `1.0`.
///
/// The value arrives already rounded to `fractionDigits` places, by the rule every SDK shares, so
/// the platform writes it and decides nothing: its own rounding, half away from zero here as the
/// rule's, never sees a value it could round another way. The locale is always the one named,
/// never the platform's default, as `platformLocale(_:)` reads it.
///
/// It is Foundation's number format style, a value that needs no lock under strict concurrency and
/// that Foundation backs with one cached formatter per locale and shape. It writes what
/// `NumberFormatter` writes on Apple platforms, and on Linux it also writes an Indian grouping,
/// `1,23,45,678`, where `NumberFormatter` there writes `12,345,678`. Where grouping is asked, a
/// locale's own minimum grouping digits apply: CLDR groups no Polish number under 10,000.
func localeNumberText(
  _ value: Double, languageTag: String, fractionDigits: Int, grouping: Bool,
  minimumFractionDigits: Int = 0
) -> String {
  let digits = min(max(fractionDigits, 0), maxFractionDigits)
  let kept = min(max(minimumFractionDigits, 0), digits)
  let style = FloatingPointFormatStyle<Double>(locale: platformLocale(languageTag))
    .precision(.fractionLength(kept...digits))
    .grouping(grouping ? .automatic : .never)
    .rounded(rule: .toNearestOrAwayFromZero)
  return value.formatted(style)
}
