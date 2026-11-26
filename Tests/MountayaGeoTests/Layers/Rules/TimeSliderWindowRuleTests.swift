import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("timeSliderWindow")
struct TimeSliderWindowRuleTests {
  private static func milliseconds(_ instant: Date?) -> Int64? {
    instant.map { Int64(($0.timeIntervalSince1970 * 1000).rounded()) }
  }

  @Test("the track runs 71 hours back and 144 ahead of the reading, an hour a stop")
  func track() {
    let window = timeSliderWindow(now: Date(timeIntervalSince1970: 1_773_480_413.9))

    #expect(timeWindowPastHours == 71)
    #expect(timeWindowFutureHours == 144)
    #expect(Self.milliseconds(window.start) == 1_773_224_813_900)
    #expect(Self.milliseconds(window.date(at: window.nowValue)) == 1_773_480_413_900)
    #expect(window.value(at: Date(timeIntervalSince1970: 1_773_480_413.9)) == 71)
  }

  @Test("a clock that reads no instant lays out a track of no instant")
  func noInstant() {
    #expect(timeSliderWindow(now: Date(timeIntervalSince1970: .nan)).start == nil)
    #expect(timeSliderWindow(now: Date(timeIntervalSince1970: .infinity)).start == nil)
    #expect(timeSliderWindow(now: Date(timeIntervalSince1970: 1e300)).start == nil)
  }

  @Test("a track is held to 8.64e15 milliseconds from the epoch at both of its ends")
  func range() {
    let limit = 8_640_000_000_000.0
    #expect(timeSliderWindow(now: Date(timeIntervalSince1970: limit)).start == nil)
    // The latest track ends at the last instant, 215 hours after its start.
    let latest: Int64 = 8_640_000_000_000_000 - 215 * 3_600_000
    #expect(
      Self.milliseconds(
        timeSliderWindow(now: Date(timeIntervalSince1970: limit - 144 * 3600)).start)
        == latest)
    #expect(timeSliderWindow(now: Date(timeIntervalSince1970: limit - 144 * 3600 + 1)).start == nil)
    #expect(
      Self.milliseconds(
        timeSliderWindow(now: Date(timeIntervalSince1970: -limit + 71 * 3600)).start)
        == -8_640_000_000_000_000)
    #expect(timeSliderWindow(now: Date(timeIntervalSince1970: -limit + 71 * 3600 - 1)).start == nil)
  }
}
