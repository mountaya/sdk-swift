import Testing

@testable import MountayaClient

@Suite("CivilCalendar")
struct CivilCalendarTests {
  @Test(
    "a date and its count of days from the epoch agree in both directions",
    arguments: [
      (1970, 1, 1, 0),
      (1969, 12, 31, -1),
      (2000, 2, 29, 11_016),
      (2000, 3, 1, 11_017),
      (2026, 3, 14, 20_526),
      (2027, 1, 15, 20_833),
      (1900, 3, 1, -25_508),
      (1600, 1, 1, -135_140),
    ]
  )
  func roundTrips(year: Int, month: Int, day: Int, days: Int) {
    #expect(CivilCalendar.days(year: year, month: month, day: day) == days)
    let date = CivilCalendar.date(days: days)
    #expect(date.year == year)
    #expect(date.month == month)
    #expect(date.day == day)
  }

  @Test("every day of four centuries round-trips")
  func everyDayRoundTrips() {
    for days in stride(from: -146_097, through: 146_097, by: 1) {
      let date = CivilCalendar.date(days: days)
      guard CivilCalendar.days(year: date.year, month: date.month, day: date.day) == days else {
        Issue.record("day \(days) came back as \(date)")
        return
      }
    }
  }

  @Test("a month's length follows the Gregorian leap rule")
  func monthLengths() {
    #expect(CivilCalendar.daysInMonth(2, of: 2024) == 29)
    #expect(CivilCalendar.daysInMonth(2, of: 2026) == 28)
    #expect(CivilCalendar.daysInMonth(2, of: 1900) == 28)
    #expect(CivilCalendar.daysInMonth(2, of: 2000) == 29)
    #expect(CivilCalendar.daysInMonth(4, of: 2026) == 30)
    #expect(CivilCalendar.daysInMonth(12, of: 2026) == 31)
    #expect(CivilCalendar.daysInMonth(13, of: 2026) == 0)
    #expect(CivilCalendar.daysInMonth(0, of: 2026) == 0)
  }
}
