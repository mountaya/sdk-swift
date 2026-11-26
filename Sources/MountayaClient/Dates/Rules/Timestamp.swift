import Foundation

/// Timestamp reads and writes the one timestamp form the contract carries: a full ISO 8601
/// date and time with a zone.
///
/// The rule is anchored, which is the whole of it: a string is a timestamp only where it is one
/// from its first character to its last, so a date alone, or a sentence that merely contains a
/// timestamp, is not one. Only a value the contract declares a timestamp is read here, and
/// every other string stays a string, however much it looks like one.
package enum Timestamp {
  private static let zero = UInt8(ascii: "0")
  private static let nine = UInt8(ascii: "9")

  /// date returns the instant a string names, or nil where the string is not, whole,
  /// `YYYY-MM-DDTHH:MM:SS`, an optional fraction of a second after a `.`, and a zone that is
  /// `Z` or an offset written `+HH:MM` or `-HH:MM`.
  ///
  /// The letters are uppercase, the offset carries its colon, and every field is in range for
  /// the date it names. A fraction runs to any number of digits, and the instant keeps its
  /// microseconds, the digits past them dropped rather than rounded, since a `Date` holds no
  /// finer an instant exactly in these years.
  static func date(from text: String) -> Date? {
    let bytes = Array(text.utf8)
    guard bytes.count >= 20,
      let year = number(bytes, at: 0..<4), bytes[4] == UInt8(ascii: "-"),
      let month = number(bytes, at: 5..<7), bytes[7] == UInt8(ascii: "-"),
      let day = number(bytes, at: 8..<10), bytes[10] == UInt8(ascii: "T"),
      let hour = number(bytes, at: 11..<13), bytes[13] == UInt8(ascii: ":"),
      let minute = number(bytes, at: 14..<16), bytes[16] == UInt8(ascii: ":"),
      let second = number(bytes, at: 17..<19),
      (1...12).contains(month), day >= 1, day <= CivilCalendar.daysInMonth(month, of: year),
      hour <= 23, minute <= 59, second <= 59
    else {
      return nil
    }

    var position = 19
    var microseconds = 0
    if bytes[position] == UInt8(ascii: ".") {
      let start = position + 1
      position = start
      while position < bytes.count, (zero...nine).contains(bytes[position]) {
        if position - start < 6 {
          microseconds = microseconds * 10 + Int(bytes[position] - zero)
        }
        position += 1
      }
      guard position > start else { return nil }
      // A fraction of fewer than six digits is padded, so `.5` is 500,000 microseconds.
      for _ in min(position - start, 6)..<6 {
        microseconds *= 10
      }
    }

    guard position < bytes.count else { return nil }
    var offset = 0
    switch bytes[position] {
    case UInt8(ascii: "Z"):
      position += 1
    case UInt8(ascii: "+"), UInt8(ascii: "-"):
      guard position + 6 <= bytes.count,
        let offsetHour = number(bytes, at: position + 1..<position + 3),
        bytes[position + 3] == UInt8(ascii: ":"),
        let offsetMinute = number(bytes, at: position + 4..<position + 6),
        offsetHour <= 23, offsetMinute <= 59
      else {
        return nil
      }
      offset = (offsetHour * 60 + offsetMinute) * 60
      if bytes[position] == UInt8(ascii: "-") {
        offset = -offset
      }
      position += 6
    default:
      return nil
    }
    guard position == bytes.count else { return nil }

    // In floating point, which holds every second of these years exactly, since `Int` is 32
    // bits on some watches and a count of seconds from 1970 outgrows that in 2038.
    let days = Double(CivilCalendar.days(year: year, month: month, day: day))
    let seconds = days * 86_400 + Double(hour * 3600 + minute * 60 + second - offset)
    return Date(timeIntervalSince1970: seconds + Double(microseconds) / 1_000_000)
  }

  /// string writes an instant in UTC, to the millisecond: `2026-03-14T09:26:53.000Z`.
  ///
  /// The digits past the millisecond are dropped, never rounded, so `.999999` is written `.999`
  /// and never as the next second. The instant is read to the microsecond it holds first, so the
  /// binary error a `Date` carries cannot drop a millisecond it does hold.
  package static func string(from date: Date) -> String {
    let microseconds = Int64((date.timeIntervalSince1970 * 1_000_000).rounded())
    var milliseconds = microseconds / 1000
    if microseconds % 1000 < 0 {
      milliseconds -= 1
    }
    let perDay: Int64 = 86_400_000
    var days = milliseconds / perDay
    var remainder = milliseconds % perDay
    if remainder < 0 {
      days -= 1
      remainder += perDay
    }
    let civil = CivilCalendar.date(days: Int(days))
    let ofDay = Int(remainder)
    return pad(civil.year, width: 4) + "-" + pad(civil.month, width: 2) + "-"
      + pad(civil.day, width: 2) + "T"
      + pad(ofDay / 3_600_000, width: 2) + ":" + pad(ofDay / 60_000 % 60, width: 2) + ":"
      + pad(ofDay / 1000 % 60, width: 2) + "." + pad(ofDay % 1000, width: 3) + "Z"
  }

  /// secondString writes an instant in UTC, to the second: `2026-11-26T00:00:00Z`, the digits
  /// past it dropped, never rounded, as a message names an instant.
  static func secondString(from date: Date) -> String {
    // `string(from:)` always ends in a dot, the three digits of the millisecond, and the `Z`.
    String(string(from: date).dropLast(5)) + "Z"
  }

  private static func number(_ bytes: [UInt8], at range: Range<Int>) -> Int? {
    guard range.upperBound <= bytes.count else { return nil }
    var value = 0
    for byte in bytes[range] {
      guard (zero...nine).contains(byte) else { return nil }
      value = value * 10 + Int(byte - zero)
    }
    return value
  }

  private static func pad(_ value: Int, width: Int) -> String {
    let digits = String(value)
    return String(repeating: "0", count: max(0, width - digits.count)) + digits
  }
}
