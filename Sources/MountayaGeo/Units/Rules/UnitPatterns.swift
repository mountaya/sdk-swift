/// UnitPatterns is how one language writes a number with each unit a measurement is stated in:
/// `{0}` stands for the number, written by the platform's locale services. The patterns are the
/// short ones, and the narrow ones for an hour and a minute of a duration, which is how `2h 35m`
/// reads in English.
///
/// Foundation formats a unit on Apple platforms and not alike on Linux, and neither `java.text` nor
/// Foundation formats one the same way on every platform, so the patterns are this table, one for
/// both native SDKs, for the seven languages the contract's `Locales` is keyed by. Each is CLDR
/// 48's, as ICU 78 carries it and as `Intl.NumberFormat` writes it, with the space each language
/// puts between a number and its unit: none, a space, a no-break space (U+00A0) or a narrow
/// no-break space (U+202F). `minimumGroupingDigits` is CLDR's too: a language of 2 groups no number
/// under 10,000, so 1531 is `1531` in Spanish and Italian and 15,310 is `15.310`.
struct UnitPatterns: Sendable, Hashable {
  let kilometer: String
  let mile: String
  let meter: String
  let foot: String
  let centimeter: String
  let inch: String
  let percent: String
  let kilometerPerHour: String
  let milePerHour: String
  let minutePerKilometer: String
  let minutePerMile: String
  let celsius: String
  let fahrenheit: String
  let hour: String
  let minute: String
  let minimumGroupingDigits: Int

  /// texts is every pattern, in the order the table writes them.
  private var texts: [String] {
    [
      kilometer, mile, meter, foot, centimeter, inch, percent, kilometerPerHour, milePerHour,
      minutePerKilometer, minutePerMile, celsius, fahrenheit, hour, minute,
    ]
  }

  /// Two rows are equal where every pattern is written with the same scalars and both group alike.
  static func == (lhs: Self, rhs: Self) -> Bool {
    zip(lhs.texts, rhs.texts).allSatisfy { sameText($0, $1) }
      && lhs.minimumGroupingDigits == rhs.minimumGroupingDigits
  }

  /// Feeds every pattern, then the grouping.
  func hash(into hasher: inout Hasher) {
    hasher.combine(texts)
    hasher.combine(minimumGroupingDigits)
  }
}

/// The English row, which a language outside the table writes, its digits still the locale's own.
private let englishPatterns = UnitPatterns(
  kilometer: "{0}\u{20}km", mile: "{0}\u{20}mi", meter: "{0}\u{20}m", foot: "{0}\u{20}ft",
  centimeter: "{0}\u{20}cm", inch: "{0}\u{20}in",
  percent: "{0}%", kilometerPerHour: "{0}\u{20}km/h", milePerHour: "{0}\u{20}mph",
  minutePerKilometer: "{0}\u{20}min/km", minutePerMile: "{0}\u{20}min/mi",
  celsius: "{0}°C", fahrenheit: "{0}°F", hour: "{0}h", minute: "{0}m",
  minimumGroupingDigits: 1)

/// The table, by primary language subtag. Every space is written by its scalar.
private let unitPatternsByLanguage: [String: UnitPatterns] = [
  "de": UnitPatterns(
    kilometer: "{0}\u{20}km", mile: "{0}\u{20}mi", meter: "{0}\u{20}m", foot: "{0}\u{20}ft",
    centimeter: "{0}\u{20}cm", inch: "{0}\u{20}in",
    percent: "{0}\u{A0}%", kilometerPerHour: "{0}\u{20}km/h", milePerHour: "{0}\u{20}mi/h",
    minutePerKilometer: "{0}\u{20}Min./km", minutePerMile: "{0}\u{20}Min./mi",
    celsius: "{0}\u{20}°C", fahrenheit: "{0}\u{20}°F", hour: "{0}h", minute: "{0}\u{20}Min.",
    minimumGroupingDigits: 1),
  "en": englishPatterns,
  "es": UnitPatterns(
    kilometer: "{0}\u{20}km", mile: "{0}\u{20}mi", meter: "{0}\u{20}m", foot: "{0}\u{20}ft",
    centimeter: "{0}\u{20}cm", inch: "{0}\u{20}in",
    percent: "{0}\u{A0}%", kilometerPerHour: "{0}\u{20}km/h", milePerHour: "{0}\u{20}mi/h",
    minutePerKilometer: "{0}\u{20}min/km", minutePerMile: "{0}\u{20}min/mi",
    celsius: "{0}\u{20}°C", fahrenheit: "{0}\u{20}°F", hour: "{0}h", minute: "{0}min",
    minimumGroupingDigits: 2),
  "fr": UnitPatterns(
    kilometer: "{0}\u{202F}km", mile: "{0}\u{202F}mi", meter: "{0}\u{202F}m",
    foot: "{0}\u{202F}pi", centimeter: "{0}\u{202F}cm", inch: "{0}\u{202F}po",
    percent: "{0}\u{A0}%", kilometerPerHour: "{0}\u{202F}km/h",
    milePerHour: "{0}\u{202F}mi/h", minutePerKilometer: "{0}\u{A0}min/km",
    minutePerMile: "{0}\u{A0}min/mi", celsius: "{0}\u{202F}°C", fahrenheit: "{0}\u{202F}°F",
    hour: "{0}h", minute: "{0}min", minimumGroupingDigits: 1),
  "it": UnitPatterns(
    kilometer: "{0}\u{20}km", mile: "{0}\u{20}mi", meter: "{0}\u{20}m", foot: "{0}\u{20}ft",
    centimeter: "{0}\u{20}cm", inch: "{0}\u{20}in",
    percent: "{0}%", kilometerPerHour: "{0}\u{20}km/h", milePerHour: "{0}\u{20}mi/h",
    minutePerKilometer: "{0}\u{20}min/km", minutePerMile: "{0}\u{20}min/mi",
    celsius: "{0}\u{20}°C", fahrenheit: "{0}\u{20}°F", hour: "{0}h", minute: "{0}min",
    minimumGroupingDigits: 2),
  "ja": UnitPatterns(
    kilometer: "{0}\u{20}km", mile: "{0}\u{20}mi", meter: "{0}\u{20}m", foot: "{0}\u{20}ft",
    centimeter: "{0}\u{20}cm", inch: "{0}\u{20}in",
    percent: "{0}%", kilometerPerHour: "{0}\u{20}km/h", milePerHour: "{0}\u{20}mph",
    minutePerKilometer: "{0}\u{20}分/km", minutePerMile: "{0}\u{20}分/mi",
    celsius: "{0}°C", fahrenheit: "{0}°F", hour: "{0}h", minute: "{0}m",
    minimumGroupingDigits: 1),
  "zh": UnitPatterns(
    kilometer: "{0}公里", mile: "{0}英里", meter: "{0}米", foot: "{0}英尺", centimeter: "{0}厘米",
    inch: "{0}英寸", percent: "{0}%",
    kilometerPerHour: "{0}\u{20}km/h", milePerHour: "{0}\u{20}mi/h",
    minutePerKilometer: "{0}分钟/公里", minutePerMile: "{0}分钟/英里", celsius: "{0}°C",
    fahrenheit: "{0}°F", hour: "{0}小时", minute: "{0}分钟", minimumGroupingDigits: 1),
]

/// unitPatterns is the patterns of a language, read by its primary subtag without regard to case,
/// as a label language is read: `fr-CA` writes French patterns and `frr` does not. A language the
/// table holds none for writes English ones, its digits still the locale's own.
func unitPatterns(_ language: String) -> UnitPatterns {
  unitPatternsByLanguage[primaryLanguageOf(language)] ?? englishPatterns
}

/// unitPatternLanguages is the languages the table holds patterns for, the ones the contract's
/// `Locales` is keyed by.
let unitPatternLanguages = Set(unitPatternsByLanguage.keys)
