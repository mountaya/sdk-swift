import Testing

@testable import MountayaGeo

@Suite("paceMinutesToClockNumber")
struct PaceMinutesToClockNumberTests {
  @Test("the seconds are carried as hundredths")
  func hundredths() {
    #expect(paceMinutesToClockNumber(13.333333333333334) == 13.2)
    #expect(paceMinutesToClockNumber(4.083333333333333) == 4.05)
    #expect(paceMinutesToClockNumber(13.999) == 14)
  }

  @Test("a pace the clock states nothing for is no number")
  func nothing() {
    for minutes in [nil, 0, -1, 0.005, .nan] as [Double?] {
      #expect(paceMinutesToClockNumber(minutes) == nil)
    }
  }
}
