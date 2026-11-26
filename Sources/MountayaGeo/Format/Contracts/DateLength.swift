/// DateLength is how much of a date a reader is shown, as the four lengths every platform's locale
/// services name a date by: Foundation's `DateFormatter.Style` and `java.text.DateFormat`'s styles.
/// The fields, their order, their words, their digits and their calendar are each the locale's own.
///
/// The cases run from the shortest to the fullest, the order `allCases` yields.
public enum DateLength: String, CaseIterable, Sendable {
  /// short is digits alone, `3/14/26` in American English.
  case short
  /// medium abbreviates the month, `Mar 14, 2026` in American English.
  case medium
  /// long writes the month in words, `March 14, 2026` in American English and `14 mars 2026` in
  /// French.
  case long
  /// full writes the weekday and the month in words, `Saturday, March 14, 2026` in American
  /// English.
  case full
}
