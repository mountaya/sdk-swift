import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("timeSliderRelease")
struct TimeSliderReleaseRuleTests {
  private static let window = timeSliderWindow(now: Date(timeIntervalSince1970: 1_773_480_413.9))

  @Test("a release on a stop pins its instant, the first and the last included")
  func pins() {
    #expect(
      timeSliderRelease(Self.window, at: 77) == TimeSliderRelease(pin: Self.window.date(at: 77)))
    #expect(timeSliderRelease(Self.window, at: 0)?.pin == Self.window.start)
    #expect(timeSliderRelease(Self.window, at: 215)?.pin == Self.window.date(at: 215))
    #expect(timeSliderRelease(Self.window, at: 77)?.pin != nil)
  }

  @Test("a release on the stop of the reading pins none")
  func now() {
    #expect(timeSliderRelease(Self.window, at: 71) == TimeSliderRelease(pin: nil))
  }

  @Test("a release on a track of no instant, or off the track, commits nothing")
  func nothing() {
    let none = timeSliderWindow(now: Date(timeIntervalSince1970: .nan))
    #expect(timeSliderRelease(none, at: 80) == nil)
    #expect(timeSliderRelease(none, at: 71) == nil)
    #expect(timeSliderRelease(Self.window, at: 216) == nil)
    #expect(timeSliderRelease(Self.window, at: -1) == nil)
  }
}
