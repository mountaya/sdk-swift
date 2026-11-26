import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("formatDistance")
struct FormatDistanceTests {
  private let metric = UnitPreferences(language: "en")
  private let imperial = UnitPreferences(language: "en", length: .imperial)

  @Test("a distance is kilometers or miles to one decimal")
  func oneDecimal() {
    #expect(formatDistance(850, units: metric) == "0.9 km")
    #expect(formatDistance(24_300, units: metric) == "24.3 km")
    #expect(formatDistance(850, units: imperial) == "0.5 mi")
    #expect(formatDistance(24_300, units: imperial) == "15.1 mi")
    #expect(formatDistance(1_234_567, units: metric) == "1,234.6 km")
  }

  @Test("the reader's language writes the number and the unit")
  func language() {
    #expect(formatDistance(24_300, units: UnitPreferences(language: "fr-FR")) == "24,3\u{202F}km")
    #expect(formatDistance(24_300, units: UnitPreferences(language: "de")) == "24,3 km")
    #expect(formatDistance(24_300, units: UnitPreferences(language: "zh")) == "24.3公里")
  }

  @Test("an unknown system is metric, and a missing distance is nothing")
  func unknownAndMissing() {
    let nautical = UnitPreferences(
      language: "en", length: RestSchema.UnitLength(rawValue: "nautical"))
    #expect(formatDistance(850, units: nautical) == "0.9 km")
    #expect(formatDistance(nil, units: metric) == "")
    #expect(formatDistance(.nan, units: metric) == "")
    #expect(formatDistance(-20, units: metric) == "0 km")
  }
}
