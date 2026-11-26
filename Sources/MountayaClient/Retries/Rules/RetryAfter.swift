import Foundation

/// RetryAfter reads a `Retry-After` header, which the API sends on every 429 of every surface and
/// on a 409 whose `Idempotency-Key` is still in use, and which a proxy in front of it may send
/// too.
///
/// Both of the header's forms are read: a delay in whole seconds, and an HTTP date in each of the
/// three formats RFC 9110 has a recipient accept, since both appear behind proxies. A value in
/// neither form is ignored, so the schedule decides the wait as if no header had come, and the
/// client never waits for a header that did not come.
enum RetryAfter {
  private static let dayNames: Set<Substring> = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
  private static let longDayNames: Set<Substring> = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
  ]
  private static let monthNames: [Substring] = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ]

  /// delay returns the wait a header asks for, in whole seconds, or nil where it asks for none the
  /// client can read.
  ///
  /// An HTTP date is read against `now`, its distance rounded up to the whole second, so that no
  /// wait ends before the instant it names: the transport waits it out and the error carries it,
  /// one figure for both. One already past is a wait of zero rather than a negative one.
  static func delay(header: String, now: Date) -> Duration? {
    let value = header.trimmingCharacters(in: [" ", "\t"])
    if !value.isEmpty, value.utf8.allSatisfy({ $0 >= 0x30 && $0 <= 0x39 }) {
      // 64 bits whatever the platform, since `Int` is 32 bits on some watches.
      return Int64(value).map { .seconds($0) }
    }
    guard let instant = httpDate(value, now: now) else { return nil }
    return max(.zero, .seconds(instant.timeIntervalSince(now).rounded(.up)))
  }

  /// httpDate reads an HTTP date in any of its three formats, each exactly as RFC 9110 spells
  /// it: the day and month names are case-sensitive, and every field has its fixed width.
  private static func httpDate(_ value: String, now: Date) -> Date? {
    let fields = value.split(separator: " ", omittingEmptySubsequences: false)

    // `Sun, 06 Nov 1994 08:49:37 GMT`, the one format a sender writes today.
    if fields.count == 6, named(fields[0], in: dayNames, comma: true), fields[5] == "GMT" {
      guard let day = number(fields[1], width: 2), let month = month(fields[2]),
        let year = number(fields[3], width: 4)
      else {
        return nil
      }
      return instant(year: year, month: month, day: day, time: fields[4])
    }

    // `Sunday, 06-Nov-94 08:49:37 GMT`, obsolete, with a two-digit year.
    if fields.count == 4, named(fields[0], in: longDayNames, comma: true), fields[3] == "GMT" {
      let date = fields[1].split(separator: "-", omittingEmptySubsequences: false)
      guard date.count == 3, let day = number(date[0], width: 2), let month = month(date[1]),
        let year = number(date[2], width: 2)
      else {
        return nil
      }
      return instant(year: fullYear(year, now: now), month: month, day: day, time: fields[2])
    }

    // `Sun Nov  6 08:49:37 1994`, obsolete, the day padded with a space and the zone implied.
    if fields.count == 5 || fields.count == 6, named(fields[0], in: dayNames, comma: false) {
      let day =
        fields.count == 5
        ? number(fields[2], width: 2)
        : fields[2].isEmpty ? number(fields[3], width: 1) : nil
      guard let day, let month = month(fields[1]),
        let year = number(fields[fields.count - 1], width: 4)
      else {
        return nil
      }
      return instant(year: year, month: month, day: day, time: fields[fields.count - 2])
    }
    return nil
  }

  /// fullYear is the year a two-digit year names: the one with those last two digits that lies
  /// no more than 50 years after `now`, as RFC 9110 has a recipient read it, and no more than 50
  /// years before it.
  private static func fullYear(_ twoDigits: Int, now: Date) -> Int {
    let current = CivilCalendar.date(
      days: Int((now.timeIntervalSince1970 / 86_400).rounded(.down))
    ).year
    let year = current - current % 100 + twoDigits
    if year > current + 50 {
      return year - 100
    }
    if year <= current - 50 {
      return year + 100
    }
    return year
  }

  /// instant is the moment a date and a time of day name in UTC, or nil where a field is out of
  /// range. A second of 60 is the leap second the Internet Message Format allows, and it reads
  /// as the next minute.
  private static func instant(year: Int, month: Int, day: Int, time: Substring) -> Date? {
    let parts = time.split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count == 3, let hour = number(parts[0], width: 2),
      let minute = number(parts[1], width: 2), let second = number(parts[2], width: 2),
      day >= 1, day <= CivilCalendar.daysInMonth(month, of: year),
      hour <= 23, minute <= 59, second <= 60
    else {
      return nil
    }
    // In floating point, which holds every second of these years exactly, since `Int` is 32
    // bits on some watches and a count of seconds from 1970 outgrows that in 2038.
    let days = Double(CivilCalendar.days(year: year, month: month, day: day))
    return Date(
      timeIntervalSince1970: days * 86_400 + Double(hour * 3600 + minute * 60 + second))
  }

  private static func named(_ field: Substring, in names: Set<Substring>, comma: Bool) -> Bool {
    guard comma else { return names.contains(field) }
    return field.hasSuffix(",") && names.contains(field.dropLast())
  }

  private static func month(_ name: Substring) -> Int? {
    monthNames.firstIndex(of: name).map { $0 + 1 }
  }

  private static func number(_ text: Substring, width: Int) -> Int? {
    guard text.utf8.count == width, text.utf8.allSatisfy({ $0 >= 0x30 && $0 <= 0x39 }) else {
      return nil
    }
    return Int(text)
  }
}
