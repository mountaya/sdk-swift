import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("waypointPropertyValue")
struct WaypointPropertyValueTests {
  private let english = UnitPreferences(language: "en")

  private func field(_ value: String, format: RestSchema.WaypointPropertyFormat?)
    -> WaypointDetails.Property
  {
    WaypointDetails.Property(key: "field", label: "Field", value: value, format: format)
  }

  @Test("a duration, a distance and a number are written by the formatters")
  func formatted() {
    #expect(waypointPropertyValue(field("3600", format: "duration"), units: english) == "1h")
    #expect(waypointPropertyValue(field("3600", format: "distance"), units: english) == "3.6 km")
    #expect(
      waypointPropertyValue(
        field("3600", format: "distance"), units: UnitPreferences(language: "fr"))
        == "3,6\u{202F}km")
    #expect(
      waypointPropertyValue(
        field("3600", format: "distance"),
        units: UnitPreferences(language: "en", length: .imperial))
        == "2.2 mi")
    #expect(waypointPropertyValue(field("3600", format: "number"), units: english) == "3,600")
    #expect(
      waypointPropertyValue(field("1234.56789", format: "number"), units: english) == "1,234.568")
    #expect(waypointPropertyValue(field(" 0x10 ", format: "number"), units: english) == "16")
  }

  @Test("a value its format cannot read, any other format and no format read as written")
  func asWritten() {
    #expect(waypointPropertyValue(field("abc", format: "number"), units: english) == "abc")
    #expect(
      waypointPropertyValue(field("about an hour", format: "duration"), units: english)
        == "about an hour")
    #expect(
      waypointPropertyValue(field("Infinity", format: "distance"), units: english) == "Infinity")
    #expect(waypointPropertyValue(field("3600", format: "text"), units: english) == "3600")
    #expect(waypointPropertyValue(field("3600", format: nil), units: english) == "3600")
    #expect(waypointPropertyValue(field("3600", format: "url"), units: english) == "3600")
  }

  @Test(
    "an instant is written only through the caller's formatter, and one that is none as written")
  func instant() {
    let date = field("2026-08-29T10:30:00Z", format: "date")
    #expect(waypointPropertyValue(date, units: english) == "2026-08-29T10:30:00Z")
    #expect(
      waypointPropertyValue(date, units: english) { _ in "29 August, 10:30" } == "29 August, 10:30")
    #expect(
      waypointPropertyValue(field("soon", format: "date"), units: english) { _ in "never" }
        == "soon")
    #expect(
      waypointPropertyValue(field("29/08", format: "date"), units: english) { _ in "never" }
        == "29/08")
  }

  @Test("a timestamp is handed to the formatter as the instant the client reads off the wire")
  func handedInstant() {
    // 2026-08-29T10:30:00Z, in every zone spelling the anchor reads, an offset to 23:59 among them.
    let halfPastTen = Date(timeIntervalSince1970: 1_787_999_400)
    for (text, instant) in [
      ("2026-08-29T10:30:00Z", halfPastTen),
      ("2026-08-29T10:30:00.250Z", halfPastTen.addingTimeInterval(0.25)),
      ("2026-08-29T12:30:00+02:00", halfPastTen),
      ("2026-08-29T05:00:00-05:30", halfPastTen),
      ("2026-08-29T10:30:00-00:00", halfPastTen),
      ("2026-08-30T10:29:00+23:59", halfPastTen),
    ] {
      var handed: Date?
      let written = waypointPropertyValue(field(text, format: "date"), units: english) {
        handed = $0
        return "an instant"
      }
      #expect(written == "an instant" && handed == instant, "\(text)")
    }
  }

  @Test("a text that names no real instant is written as it stands, never as a later instant")
  func noRealInstant() {
    for text in [
      "2024-02-30T10:00:00Z",
      "2024-13-01T10:00:00Z",
      "2024-03-01T24:00:00Z",
      "2024-03-01T10:00:60Z",
      "2024-03-01T10:61:00Z",
      "2024-03-01T10:00:00+25:00",
      "2024-03-01T10:00:00+0100",
      "2024-03-01T10:00:00Z ",
    ] {
      let written = waypointPropertyValue(field(text, format: "date"), units: english) { _ in
        "an instant"
      }
      #expect(written == text, "\(text)")
    }
  }
}
