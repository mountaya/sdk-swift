import Testing

@testable import MountayaGeo

@Suite("paceClockNumberToMinutes")
struct PaceClockNumberToMinutesTests {
  @Test("the hundredths are read as seconds")
  func seconds() {
    #expect(paceClockNumberToMinutes(13.2) == 13.333333333333334)
    #expect(paceClockNumberToMinutes(4.05) == 4.083333333333333)
  }

  @Test("seconds past fifty-nine carry into the minutes")
  func carry() {
    #expect(paceClockNumberToMinutes(13.6) == 14)
    #expect(paceClockNumberToMinutes(13.9) == 14.5)
  }

  @Test("a number that is no positive finite number is no pace")
  func nothing() {
    for value in [nil, 0, -13.2, .nan, .infinity] as [Double?] {
      #expect(paceClockNumberToMinutes(value) == nil)
    }
  }
}
