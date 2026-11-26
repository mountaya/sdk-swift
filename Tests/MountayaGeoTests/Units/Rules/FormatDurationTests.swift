import Testing

@testable import MountayaGeo

@Suite("formatDuration")
struct FormatDurationTests {
  private let english = UnitPreferences(language: "en")

  @Test("a duration is its hours and minutes, each with its narrow unit")
  func narrowUnits() {
    #expect(formatDuration(9_320, units: english) == "2h 35m")
    #expect(formatDuration(7_170, units: english) == "2h")
    #expect(formatDuration(42, units: english) == "1m")
    #expect(formatDuration(9_320, units: UnitPreferences(language: "fr")) == "2h 35min")
    #expect(formatDuration(9_320, units: UnitPreferences(language: "zh")) == "2小时 35分钟")
  }

  @Test("no duration, or one under half a minute, is nothing")
  func nothing() {
    for seconds in [nil, 0, -60, 29, .nan] as [Double?] {
      #expect(formatDuration(seconds, units: english) == "", "\(String(describing: seconds))")
    }
  }
}
