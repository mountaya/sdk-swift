import Foundation
import Testing

@testable import MountayaGeo

@Suite("formatDateTime")
struct FormatDateTimeTests {
  /// 2026-03-14T00:00:00Z.
  private let piDay = Date(timeIntervalSince1970: 1_773_446_400)

  @Test("a date is written in the locale at the length asked, and at the long one where none is")
  func date() {
    #expect(formatDateTime(piDay, locale: "en-US", timeZone: "UTC") == "March 14, 2026")
    #expect(
      formatDateTime(piDay, locale: "fr_FR", timeZone: "UTC", dateLength: .long) == "14 mars 2026")
    #expect(
      formatDateTime(piDay, locale: "en-US", timeZone: "UTC", dateLength: .full)
        == "Saturday, March 14, 2026")
    #expect(
      formatDateTime(piDay, locale: "en-US", timeZone: "UTC", dateLength: .short) == "3/14/26")
  }

  /// The reference instant is 13:00 in Auckland, on New Zealand's daylight saving time: German
  /// writes it on a 24-hour clock and Korean on a 12-hour one, the day period first, whatever clock
  /// the device running the test is set to.
  @Test("a time of day alone is written at the length asked, on the locale's own clock")
  func time() {
    #expect(
      formatDateTime(piDay, locale: "de-DE", timeZone: "Pacific/Auckland", timeLength: .short)
        == "13:00")
    #expect(
      formatDateTime(piDay, locale: "ko-KR", timeZone: "Pacific/Auckland", timeLength: .short)
        == "오후 1:00")
    // The medium length adds the second.
    #expect(
      formatDateTime(piDay, locale: "ja-JP", timeZone: "Asia/Tokyo", timeLength: .medium)
        == "9:00:00")
    // Nepali writes its time in its own digits, never assembled Latin ones.
    #expect(
      formatDateTime(piDay, locale: "ne-NP", timeZone: "Asia/Kathmandu", timeLength: .short)
        == "\u{966}\u{96B}:\u{96A}\u{96B}")
  }

  @Test("a date with a time is joined as the locale joins a date of that length")
  func dateAndTime() {
    // A short French date joins its time with a space, whatever the time's length.
    #expect(
      formatDateTime(
        piDay, locale: "fr-FR", timeZone: "Asia/Kathmandu", dateLength: .short,
        timeLength: .medium) == "14/03/2026 05:45:00")
    // A medium German date joins its time with a comma: never a separator of Geo's own.
    #expect(
      formatDateTime(
        piDay, locale: "de-DE", timeZone: "America/New_York", dateLength: .medium,
        timeLength: .short) == "13.03.2026, 20:00")
    // Korean keeps its 12-hour clock beside a date too.
    #expect(
      formatDateTime(
        piDay, locale: "ko-KR", timeZone: "Pacific/Auckland", dateLength: .medium,
        timeLength: .short) == "2026. 3. 14. 오후 1:00")
  }

  /// Midnight in UTC is 20:00 the evening before in New York, on its daylight saving time from
  /// 8 March 2026: 19:00 would be the standard time, and the 14th the date in UTC.
  @Test("the date and the time are the zone's; a zone the platform does not know writes nothing")
  func zone() {
    #expect(
      formatDateTime(piDay, locale: "en-US", timeZone: "America/Los_Angeles") == "March 13, 2026")
    #expect(
      formatDateTime(piDay, locale: "de-DE", timeZone: "America/New_York", timeLength: .short)
        == "20:00")
    #expect(
      formatDateTime(
        piDay, locale: "zh-CN", timeZone: "America/New_York", dateLength: .medium,
        timeLength: .short) == "2026年3月13日 20:00")
    #expect(formatDateTime(piDay, locale: "en-US", timeZone: "Mars/Olympus_Mons") == nil)
    #expect(
      formatDateTime(piDay, locale: "en-US", timeZone: "Mars/Olympus_Mons", timeLength: .short)
        == nil)
    #expect(
      formatDateTime(
        piDay, locale: "en-US", timeZone: "Mars/Olympus_Mons", dateLength: .medium,
        timeLength: .short) == nil)
  }

  /// The tz database keeps a renamed zone's old name in its `backward` file, which an Apple
  /// platform carries and a Linux image may leave out with `tzdata-legacy`, as the Swift images do:
  /// there `TimeZone(identifier:)` still answers the name, and the formatter, which loads the
  /// zone's data by that name, stops the process where it finds none. A zone the platform's data
  /// lacks writes nothing (`geo.format.locale-services`), so the name writes as its zone where the
  /// data holds it and nothing where it does not, and never stops the process: the gate's Linux
  /// legs run the second branch, macOS the first.
  @Test("a legacy zone name writes as its zone where the data holds it, and nothing where not")
  func legacyZone() throws {
    // English parts the time and its day period with U+202F NARROW NO-BREAK SPACE.
    let renamed = [
      ("Asia/Calcutta", "Asia/Kolkata", "Mar 14, 2026 at 5:30\u{202F}AM"),
      ("US/Eastern", "America/New_York", "Mar 13, 2026 at 8:00\u{202F}PM"),
    ]
    for (legacy, current, written) in renamed {
      let asCurrent = formatDateTime(
        piDay, locale: "en-US", timeZone: current, dateLength: .medium, timeLength: .short)
      let asLegacy = formatDateTime(
        piDay, locale: "en-US", timeZone: legacy, dateLength: .medium, timeLength: .short)

      #expect(asCurrent == written)
      #if canImport(Darwin)
        #expect(asLegacy == written, "\(legacy)")
      #else
        let held = FileManager.default.fileExists(atPath: "/usr/share/zoneinfo/\(legacy)")
        #expect(asLegacy == (held ? written : nil), "\(legacy), its data held: \(held)")
        // A date alone and a time alone take the same zone, and answer alike.
        #expect(
          (formatDateTime(piDay, locale: "en-US", timeZone: legacy) == nil)
            == (asLegacy == nil))
        #expect(
          (formatDateTime(piDay, locale: "en-US", timeZone: legacy, timeLength: .short) == nil)
            == (asLegacy == nil))
      #endif
    }
  }

  #if os(macOS) || os(Linux)
    /// A formatter's calendar takes its own zone where none is set, the process's, which a server's
    /// TZ names: on Linux a legacy name there stops the process at every date a formatter that
    /// takes it writes, whatever zone the call names. The child process sets its own zone to one, and writes New York's date.
    @Test("the process's own zone never reaches the formatter, a legacy name included")
    func processZone() async {
      await #expect(processExitsWith: .success) {
        setenv("TZ", "US/Eastern", 1)
        NSTimeZone.resetSystemTimeZone()
        let written = formatDateTime(
          Date(timeIntervalSince1970: 1_773_446_400), locale: "en-US",
          timeZone: "America/New_York", dateLength: .medium, timeLength: .short)
        exit(written == "Mar 13, 2026 at 8:00\u{202F}PM" ? 0 : 1)
      }
    }
  #endif

  /// The calendar is always the Gregorian one, whatever the locale keeps or its tag names
  /// (`geo.format.locale-services`): the fields, their order, their words and their digits stay the
  /// locale's own.
  @Test("the calendar is the Gregorian one, whatever the locale keeps or its tag names")
  func calendar() {
    // Persian keeps the Solar Hijri calendar, and its digits stay its own.
    #expect(
      formatDateTime(piDay, locale: "fa-IR", timeZone: "UTC")
        == "\u{6F1}\u{6F4} \u{645}\u{627}\u{631}\u{633} \u{6F2}\u{6F0}\u{6F2}\u{6F6}")
    // Thai keeps the Buddhist calendar, and its Gregorian long date names the Christian era.
    #expect(formatDateTime(piDay, locale: "th-TH", timeZone: "UTC") == "14 มีนาคม ค.ศ. 2026")
    #expect(
      formatDateTime(piDay, locale: "th-TH-u-ca-buddhist", timeZone: "UTC")
        == "14 มีนาคม ค.ศ. 2026")
    #expect(
      formatDateTime(piDay, locale: "th-TH-u-ca-gregory", timeZone: "UTC")
        == "14 มีนาคม ค.ศ. 2026")
    #expect(
      formatDateTime(piDay, locale: "ja-JP-u-ca-japanese", timeZone: "UTC") == "2026年3月14日")
    // Beside a time too: 2026, never 2569.
    #expect(
      formatDateTime(
        piDay, locale: "th-TH-u-ca-buddhist", timeZone: "UTC", dateLength: .medium,
        timeLength: .medium) == "14 มี.ค. 2026 00:00:00")
  }
}
