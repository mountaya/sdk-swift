/// CivilCalendar is the arithmetic of the proleptic Gregorian calendar, in whole days from the
/// Unix epoch.
///
/// The client reads and writes timestamps in UTC by this arithmetic rather than through a
/// platform calendar or formatter, since what those accept is the platform's decision and can
/// move with an OS release, where the timestamp's grammar is the contract's.
enum CivilCalendar {
  /// days returns the count of days from 1970-01-01 to a date, negative before it.
  static func days(year: Int, month: Int, day: Int) -> Int {
    let shifted = month <= 2 ? year - 1 : year
    let era = (shifted >= 0 ? shifted : shifted - 399) / 400
    let yearOfEra = shifted - era * 400
    let dayOfYear = (153 * (month > 2 ? month - 3 : month + 9) + 2) / 5 + day - 1
    let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    return era * 146_097 + dayOfEra - 719_468
  }

  /// date returns the date a count of days from 1970-01-01 falls on.
  static func date(days: Int) -> (year: Int, month: Int, day: Int) {
    let shifted = days + 719_468
    let era = (shifted >= 0 ? shifted : shifted - 146_096) / 146_097
    let dayOfEra = shifted - era * 146_097
    let yearOfEra =
      (dayOfEra - dayOfEra / 1460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
    let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
    let shiftedMonth = (5 * dayOfYear + 2) / 153
    let day = dayOfYear - (153 * shiftedMonth + 2) / 5 + 1
    let month = shiftedMonth < 10 ? shiftedMonth + 3 : shiftedMonth - 9
    return (yearOfEra + era * 400 + (month <= 2 ? 1 : 0), month, day)
  }

  /// daysInMonth returns how many days a month of a year has, or zero for a month that is not
  /// one.
  static func daysInMonth(_ month: Int, of year: Int) -> Int {
    switch month {
    case 1, 3, 5, 7, 8, 10, 12: return 31
    case 4, 6, 9, 11: return 30
    case 2: return isLeap(year) ? 29 : 28
    default: return 0
    }
  }

  private static func isLeap(_ year: Int) -> Bool {
    year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
  }
}
