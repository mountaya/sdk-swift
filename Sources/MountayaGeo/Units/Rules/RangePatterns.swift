/// RangePatterns is how one language writes a range of two numbers and an approximate number, for
/// `formatAltitudeRange(min:max:units:)`: `{0}` and `{1}` stand for the numbers, each written by the
/// platform's locale services.
///
/// Foundation publishes no range formatting of numbers, on Apple platforms or on Linux, so the
/// patterns are this table, beside the unit patterns, for the seven languages the contract's
/// `Locales` is keyed by: CLDR 48's range and approximately patterns, as ICU 78 carries them and as
/// `Intl.NumberFormat`'s `formatRange` writes them, the separator an en dash in English, French and
/// German, a hyphen-minus in Spanish, Italian and Chinese and a wave dash in Japanese, and the
/// approximation a tilde, `≃` in French, `≈` in German and `約` in Japanese.
struct RangePatterns: Sendable, Hashable {
  let range: String
  let approximately: String
}

/// The English row, which a language outside the table writes.
private let englishRangePatterns = RangePatterns(
  range: "{0}\u{2013}{1}", approximately: "~{0}")

/// The table, by primary language subtag.
private let rangePatternsByLanguage: [String: RangePatterns] = [
  "de": RangePatterns(range: "{0}\u{2013}{1}", approximately: "\u{2248}{0}"),
  "en": englishRangePatterns,
  "es": RangePatterns(range: "{0}-{1}", approximately: "~{0}"),
  "fr": RangePatterns(range: "{0}\u{2013}{1}", approximately: "\u{2243}{0}"),
  "it": RangePatterns(range: "{0}-{1}", approximately: "~{0}"),
  "ja": RangePatterns(range: "{0}\u{FF5E}{1}", approximately: "\u{7D04}{0}"),
  "zh": RangePatterns(range: "{0}-{1}", approximately: "~{0}"),
]

/// rangePatterns is the range and approximately patterns of a language, read by its primary subtag
/// without regard to case as `unitPatterns(_:)` reads it, English for a language the table holds
/// none for.
func rangePatterns(_ language: String) -> RangePatterns {
  rangePatternsByLanguage[primaryLanguageOf(language)] ?? englishRangePatterns
}

/// rangePatternLanguages is the languages the table holds patterns for.
let rangePatternLanguages = Set(rangePatternsByLanguage.keys)
