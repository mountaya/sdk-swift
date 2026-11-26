import Foundation

/// formatDateTime writes an instant for a reader of `locale`, a BCP 47 language tag, as it falls in
/// `timeZone`, an IANA zone name such as `Europe/Paris`, through the platform's locale services:
/// its date at `dateLength`, its time of day at `timeLength`, or both, each in the locale's own
/// style of that length, its fields, their order, its words and its digits. Midnight in UTC on
/// 2026-03-14 is `March 14, 2026` in American English at the long date, `13:00` in German and
/// `오후 1:00` in Korean at the short time in Auckland, and `13.03.2026, 20:00` in German at the
/// medium date and the short time in New York.
///
/// Naming neither length writes the date at `.long`. A time keeps the locale's hour cycle, 12 or 24
/// hours, whatever clock the device is set to, and names no zone. A date with a time is joined as
/// the locale joins a date of that length and a time, never by a separator of Geo's own.
///
/// The zone and the locale are arguments, never the platform's defaults, and the instant is placed
/// at the offset the zone keeps at that instant, so 2026-03-14T00:00:00Z is 20:00 on the 13th in
/// New York. It is written in the Gregorian calendar, whatever calendar the locale keeps or its
/// tag's `-u-ca-` extension names (`geo.format.locale-services`): Thai (`th-TH`) writes the year
/// 2026, `14 มีนาคม ค.ศ. 2026`, and never the Buddhist 2569. An underscore in `locale` parts
/// subtags as a hyphen does, and a value that is no language tag reads as English. Nil where the
/// platform's zone data holds no zone of that name: a legacy name the tz database keeps for a zone
/// renamed, `Asia/Calcutta` for `Asia/Kolkata`, writes as that zone on Apple platforms, and nothing
/// on a Linux system whose zone files leave the legacy names out, as one without `tzdata-legacy`
/// does.
public func formatDateTime(
  _ instant: Date, locale: String, timeZone: String, dateLength: DateLength? = nil,
  timeLength: TimeLength? = nil
) -> String? {
  localeDateText(
    instant, languageTag: languageTagOf(locale), timeZone: timeZone,
    dateLength: dateLength ?? (timeLength == nil ? .long : nil), timeLength: timeLength)
}
