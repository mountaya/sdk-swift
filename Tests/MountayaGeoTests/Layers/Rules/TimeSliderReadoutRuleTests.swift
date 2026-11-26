import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("timeSliderReadout")
struct TimeSliderReadoutRuleTests {
  private static let window = timeSliderWindow(now: Date(timeIntervalSince1970: 1_773_480_413.9))

  private static func offset(_ value: Int, in window: TimeSliderWindow = window) -> String {
    let readout = timeSliderReadout(window, at: value)
    return readout.word + (readout.count.map { " \($0)" } ?? "")
  }

  @Test("the reading reads now, and its instant")
  func now() {
    let readout = timeSliderReadout(Self.window, at: 71)
    #expect(
      readout
        == TimeSliderReadout(instant: Self.window.date(at: 71), word: "layers.timeNow", count: nil))
  }

  @Test("under a day reads whole hours, either side")
  func hours() {
    #expect(Self.offset(70) == "layers.timeHoursAgo 1")
    #expect(Self.offset(72) == "layers.timeHoursAhead 1")
    #expect(Self.offset(48) == "layers.timeHoursAgo 23")
    #expect(Self.offset(94) == "layers.timeHoursAhead 23")
  }

  @Test("from a day on reads whole days, truncated toward the reading")
  func days() {
    #expect(Self.offset(95) == "layers.timeDaysAhead 1")
    #expect(Self.offset(118) == "layers.timeDaysAhead 1")
    #expect(Self.offset(47) == "layers.timeDaysAgo 1")
    #expect(Self.offset(24) == "layers.timeDaysAgo 1")
    #expect(Self.offset(23) == "layers.timeDaysAgo 2")
    #expect(Self.offset(0) == "layers.timeDaysAgo 2")
    #expect(Self.offset(215) == "layers.timeDaysAhead 6")
  }

  @Test("a stop that stands for no instant reads its offset alone")
  func noInstant() {
    let none = timeSliderWindow(now: Date(timeIntervalSince1970: .nan))
    #expect(
      timeSliderReadout(none, at: 80)
        == TimeSliderReadout(instant: nil, word: "layers.timeHoursAhead", count: 9))
    #expect(Self.offset(0, in: none) == "layers.timeDaysAgo 2")
  }
}
