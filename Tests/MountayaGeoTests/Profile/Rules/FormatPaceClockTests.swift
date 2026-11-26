import Testing

@testable import MountayaGeo

@Suite("formatPaceClock")
struct FormatPaceClockTests {
  @Test("a pace is a clock of minutes and two-digit seconds")
  func clock() {
    #expect(formatPaceClock(13.333333333333334) == "13:20")
    #expect(formatPaceClock(4.083333333333333) == "4:05")
    #expect(formatPaceClock(60) == "60:00")
    #expect(formatPaceClock(125.5) == "125:30")
  }

  @Test("the seconds are rounded before the split, so none reads sixty")
  func roundedFirst() {
    #expect(formatPaceClock(13.999) == "14:00")
    #expect(formatPaceClock(0.01) == "0:01")
  }

  @Test("a pace that is no positive number, or rounds to no second, is nothing")
  func nothing() {
    for minutes in [nil, 0, -4, 0.005, .nan, .infinity] as [Double?] {
      #expect(formatPaceClock(minutes) == "", "\(String(describing: minutes))")
    }
    #expect(clockSeconds(0.008) == nil)
    #expect(clockSeconds(0.0084) == 1)
    #expect(clockSeconds(1e300) == nil)
  }
}
