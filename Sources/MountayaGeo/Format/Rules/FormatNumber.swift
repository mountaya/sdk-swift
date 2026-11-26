/// formatNumber writes a value for a reader of `locale`, a BCP 47 language tag such as `ar-EG`,
/// through the platform's locale services: the locale's own digits, decimal mark, minus sign and
/// grouping, never digits assembled by hand, which are Latin digits by construction. 1531 is
/// `1,531` in American English and `١٬٥٣١` in Egyptian Arabic.
///
/// The value is rounded to `maximumFractionDigits` places, half away from zero on its decimal
/// value, before the platform sees it, and written with no fraction digit it does not need: 24.3
/// to one place is `24,3` in French. The default of three places is every locale's own for a plain
/// number. The places are read within 0 and 20. An underscore in `locale` parts subtags as a hyphen
/// does, and a value that is no language tag reads as English. A value that is no finite number is
/// the empty string.
///
/// The digits are those of the locale data the platform carries, so a platform whose data writes
/// another numbering system for a locale writes that one: the data of macOS 27 and of the Linux
/// toolchain at 6.4.0 write Bengali in Latin digits, `1,531`, where the contract's fixture writes
/// `১,৫৩১`.
public func formatNumber(_ value: Double, locale: String, maximumFractionDigits: Int = 3) -> String
{
  guard value.isFinite else { return "" }
  let digits = min(max(maximumFractionDigits, 0), maxFractionDigits)
  return localeNumberText(
    roundHalfAwayFromZero(value, fractionDigits: digits),
    languageTag: languageTagOf(locale),
    fractionDigits: digits,
    grouping: true
  )
}
