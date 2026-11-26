import Foundation
import Testing

@testable import MountayaGeo

@Suite("localeDateText")
struct LocaleDateTextTests {
  /// 2026-03-14T00:00:00Z.
  private let piDay = Date(timeIntervalSince1970: 1_773_446_400)

  @Test("a date is written in the locale and the zone it names")
  func written() {
    #expect(
      localeDateText(
        piDay, languageTag: "en-US", timeZone: "UTC", dateLength: .long, timeLength: nil)
        == "March 14, 2026")
    #expect(
      localeDateText(
        piDay, languageTag: "fr-FR", timeZone: "UTC", dateLength: .long, timeLength: nil)
        == "14 mars 2026")
    // Midnight in UTC is the evening before in New York.
    #expect(
      localeDateText(
        piDay, languageTag: "en-US", timeZone: "America/New_York", dateLength: .long,
        timeLength: nil) == "March 13, 2026")
  }

  /// Each length is the locale's own style, never a field template: a short date has a two-digit
  /// year and a medium German one digits alone.
  @Test("each date length is the locale's own style")
  func lengths() {
    #expect(
      localeDateText(
        piDay, languageTag: "en-US", timeZone: "UTC", dateLength: .short, timeLength: nil)
        == "3/14/26")
    #expect(
      localeDateText(
        piDay, languageTag: "en-US", timeZone: "UTC", dateLength: .medium, timeLength: nil)
        == "Mar 14, 2026")
    #expect(
      localeDateText(
        piDay, languageTag: "de-DE", timeZone: "UTC", dateLength: .medium, timeLength: nil)
        == "14.03.2026")
    #expect(
      localeDateText(
        piDay, languageTag: "en-US", timeZone: "UTC", dateLength: .full, timeLength: nil)
        == "Saturday, March 14, 2026")
  }

  /// A time alone is the locale's time style: the short one its hour and minute, the medium one its
  /// second too, each on the locale's clock.
  @Test("each time length is the locale's own style, and a date with a time the locale's join")
  func times() {
    #expect(
      localeDateText(
        piDay, languageTag: "de-DE", timeZone: "Pacific/Auckland", dateLength: nil,
        timeLength: .short) == "13:00")
    #expect(
      localeDateText(
        piDay, languageTag: "de-DE", timeZone: "Pacific/Auckland", dateLength: nil,
        timeLength: .medium) == "13:00:00")
    #expect(
      localeDateText(
        piDay, languageTag: "de-DE", timeZone: "America/New_York", dateLength: .medium,
        timeLength: .short) == "13.03.2026, 20:00")
    #expect(
      localeDateText(
        piDay, languageTag: "fr-FR", timeZone: "Asia/Kathmandu", dateLength: .short,
        timeLength: .medium) == "14/03/2026 05:45:00")
  }

  /// The person's 12- or 24-hour setting is a preference `Locale.current` carries. The locale here
  /// is read from the tag alone, so it answers the tag's own hour cycle, and so does what it
  /// writes: a device set to either clock would make one of these two read the other way.
  @Test("a time is on the locale's own clock, whatever clock the device is set to")
  func hourCycle() {
    #expect(platformLocale("ko-KR").hourCycle == .oneToTwelve)
    #expect(platformLocale("de-DE").hourCycle == .zeroToTwentyThree)
    #expect(
      localeDateText(
        piDay, languageTag: "ko-KR", timeZone: "Pacific/Auckland", dateLength: nil,
        timeLength: .short) == "오후 1:00")
    #expect(
      localeDateText(
        piDay, languageTag: "de-DE", timeZone: "Pacific/Auckland", dateLength: nil,
        timeLength: .short) == "13:00")
  }

  /// Each formatter is cached under the locale, both lengths and the zone, so one built for a
  /// length is never handed out for another: asked in this order, a key that forgot the time's
  /// length, or a date alone beside a date with a time, would write the first answer again.
  @Test("a formatter is kept apart for each pair of lengths")
  func keptApart() {
    let tag = "it-IT"
    let zone = "Europe/Rome"
    let written = [
      localeDateText(piDay, languageTag: tag, timeZone: zone, dateLength: nil, timeLength: .short),
      localeDateText(piDay, languageTag: tag, timeZone: zone, dateLength: nil, timeLength: .medium),
      localeDateText(piDay, languageTag: tag, timeZone: zone, dateLength: .short, timeLength: nil),
      localeDateText(
        piDay, languageTag: tag, timeZone: zone, dateLength: .short, timeLength: .short),
      localeMomentText(piDay, languageTag: tag, timeZone: zone),
    ]
    #expect(!written.contains(nil), "\(written)")
    #expect(Set(written).count == written.count, "\(written)")
  }

  @Test("a zone the platform does not know writes nothing")
  func unknownZone() {
    #expect(
      localeDateText(
        piDay, languageTag: "en-US", timeZone: "Not/AZone", dateLength: .long, timeLength: nil)
        == nil)
    #expect(
      localeDateText(
        piDay, languageTag: "en-US", timeZone: "Not/AZone", dateLength: nil, timeLength: .short)
        == nil)
  }

  /// A time slider's moment goes through the same formatter, so a legacy zone name answers as a
  /// date does: its zone's where the platform's data holds the name, nothing where it does not.
  @Test("a moment in a legacy zone name is its zone's where the data holds it, and none where not")
  func legacyZoneMoment() {
    let legacy = localeMomentText(piDay, languageTag: "en-GB", timeZone: "Asia/Calcutta")
    let current = localeMomentText(piDay, languageTag: "en-GB", timeZone: "Asia/Kolkata")

    #expect(current?.contains("05:30") == true, "\(current ?? "nil")")
    #if canImport(Darwin)
      #expect(legacy == current)
    #else
      let held = FileManager.default.fileExists(atPath: "/usr/share/zoneinfo/Asia/Calcutta")
      #expect(legacy == (held ? current : nil), "its data held: \(held)")
    #endif
  }

  @Test("a formatter built once writes the same date from any number of tasks")
  func concurrent() async {
    let piDay = piDay
    let written = await withTaskGroup(of: String?.self) { group in
      for index in 0..<100 {
        group.addTask {
          localeDateText(
            piDay, languageTag: index.isMultiple(of: 2) ? "en-US" : "fr-FR", timeZone: "UTC",
            dateLength: .long, timeLength: nil)
        }
      }
      var all: Set<String?> = []
      for await text in group { all.insert(text) }
      return all
    }
    #expect(written == ["March 14, 2026", "14 mars 2026"])
  }

  /// 2026-03-14T09:26:53.900Z.
  private let pinned = Date(timeIntervalSince1970: 1_773_480_413.9)

  @Test("a moment is its weekday, day, month, hour and minute in the locale and the zone named")
  func moment() throws {
    let moment = pinned
    let british = try #require(
      localeMomentText(moment, languageTag: "en-GB", timeZone: "UTC"))
    for part in ["Sat", "14", "Mar", "09:26"] {
      #expect(british.contains(part), "\(british)")
    }
    #expect(!british.contains("2026"), "a moment names no year")
    let french = try #require(localeMomentText(moment, languageTag: "fr-FR", timeZone: "UTC"))
    for part in ["sam.", "14", "mars", "09:26"] {
      #expect(french.contains(part), "\(french)")
    }
    // 09:26 in UTC is 10:26 in Paris, a winter's day.
    let paris = try #require(
      localeMomentText(moment, languageTag: "en-GB", timeZone: "Europe/Paris"))
    #expect(paris.contains("10:26"), "\(paris)")
    #expect(localeMomentText(moment, languageTag: "en-GB", timeZone: "Not/AZone") == nil)
  }
}
