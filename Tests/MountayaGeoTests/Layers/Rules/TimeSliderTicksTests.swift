import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("timeSliderTicks")
struct TimeSliderTicksTests {
  private static let ticks: [TimeSliderTick] = [
    TimeSliderTick(value: 23, word: "layers.timeMinus2d"), TimeSliderTick(value: 47, word: nil),
    TimeSliderTick(value: 71, word: "layers.timeNow"), TimeSliderTick(value: 95, word: nil),
    TimeSliderTick(value: 119, word: "layers.timePlus2d"), TimeSliderTick(value: 143, word: nil),
    TimeSliderTick(value: 167, word: nil), TimeSliderTick(value: 191, word: "layers.timePlus5d"),
    TimeSliderTick(value: 215, word: nil),
  ]

  @Test("a tick at the reading and every whole day either side, the labelled days carrying words")
  func ticks() {
    #expect(
      timeSliderTicks(timeSliderWindow(now: Date(timeIntervalSince1970: 1_773_480_413.9)))
        == Self.ticks)
    #expect(timeSliderDayStops == 24)
    #expect(timeSliderLabelledDays.map(\.days) == [-2, 0, 2, 5])
  }

  @Test("a track of no instant is ticked as any other")
  func noInstant() {
    #expect(timeSliderTicks(timeSliderWindow(now: Date(timeIntervalSince1970: .nan))) == Self.ticks)
  }
}
