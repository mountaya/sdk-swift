import Testing

@testable import MountayaGeo

@Suite("splitDuration")
struct SplitDurationTests {
  @Test("the total is rounded to whole minutes before it is split")
  func roundedFirst() {
    #expect(splitDuration(9_320) == DurationSplit(hours: 2, minutes: 35))
    #expect(splitDuration(7_169) == DurationSplit(hours: 1, minutes: 59))
    #expect(splitDuration(7_170) == DurationSplit(hours: 2, minutes: 0))
    #expect(splitDuration(3_599) == DurationSplit(hours: 1, minutes: 0))
  }

  @Test("a half minute rounds up, and any less to no minute")
  func halfMinute() {
    #expect(splitDuration(150) == DurationSplit(hours: 0, minutes: 3))
    #expect(splitDuration(30) == DurationSplit(hours: 0, minutes: 1))
    #expect(splitDuration(29) == DurationSplit(hours: 0, minutes: 0))
    #expect(splitDuration(29.999999999999996) == DurationSplit(hours: 0, minutes: 0))
  }

  @Test("hours are never carried into days")
  func noDays() {
    #expect(splitDuration(86_400) == DurationSplit(hours: 24, minutes: 0))
    #expect(splitDuration(360_060) == DurationSplit(hours: 100, minutes: 1))
  }

  @Test("a missing, zero, negative or non-finite duration is no duration")
  func noDuration() {
    for seconds in [nil, 0, -0.0, -60, .nan, .infinity] as [Double?] {
      #expect(splitDuration(seconds) == nil, "\(String(describing: seconds))")
    }
  }

  /// Kotlin's Double.toLong saturates; a Swift Int(_:) of the same double would trap.
  @Test("a count of minutes past the range of Int is the greatest one")
  func saturates() {
    #expect(
      splitDuration(.greatestFiniteMagnitude) == DurationSplit(hours: Int.max / 60, minutes: 7))
  }

  @Test("a half is read exactly")
  func halfUp() {
    #expect(roundHalfUp(0.5) == 1)
    #expect(roundHalfUp(0.49999999999999994) == 0)
    #expect(roundHalfUp(2.5) == 3)
    #expect(roundHalfUp(2) == 2)
  }
}
