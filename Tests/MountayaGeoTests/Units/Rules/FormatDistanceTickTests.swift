import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatDistanceTick")
struct FormatDistanceTickTests {
  private let metric = UnitPreferences(language: "en")
  private let imperial = UnitPreferences(language: "en", length: .imperial)

  @Test("a stop keeps the fraction digits it needs, zeros included, and a whole step reads whole")
  func digits() {
    #expect(
      formatDistanceTick(DistanceTick(value: 0.5, meters: 500, fractionDigits: 1), units: metric)
        == "0.5 km")
    #expect(
      formatDistanceTick(DistanceTick(value: 1, meters: 1_000, fractionDigits: 1), units: metric)
        == "1.0 km", "a stop beside 0.5 km reads as a different number")
    #expect(
      formatDistanceTick(DistanceTick(value: 5, meters: 5_000, fractionDigits: 0), units: metric)
        == "5 km")
    #expect(
      formatDistanceTick(
        DistanceTick(value: 0.25, meters: 250, fractionDigits: 2), units: metric) == "0.25 km")
  }

  @Test("the reader's system names the unit, the stop already in it")
  func system() {
    #expect(
      formatDistanceTick(
        DistanceTick(value: 2, meters: 3_218.688, fractionDigits: 0), units: imperial) == "2 mi")
  }

  @Test("the reader's language writes the number and the unit")
  func language() {
    let tick = DistanceTick(value: 1.5, meters: 1_500, fractionDigits: 1)

    #expect(formatDistanceTick(tick, units: UnitPreferences(language: "fr-FR")) == "1,5\u{202F}km")
    #expect(formatDistanceTick(tick, units: UnitPreferences(language: "de")) == "1,5 km")
    #expect(formatDistanceTick(tick, units: UnitPreferences(language: "zh")) == "1.5公里")
  }
}
