import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("TimeSliderReadout")
struct TimeSliderReadoutTests {
  @Test("two readouts are equal where they read one instant and one word, counting the same")
  func equality() {
    let instant = Date(timeIntervalSince1970: 1_773_484_013.9)
    let readout = TimeSliderReadout(instant: instant, word: "layers.timeHoursAhead", count: 1)

    #expect(
      readout == TimeSliderReadout(instant: instant, word: "layers.timeHoursAhead", count: 1))
    #expect(readout != TimeSliderReadout(instant: nil, word: "layers.timeHoursAhead", count: 1))
    #expect(readout != TimeSliderReadout(instant: instant, word: "layers.timeHoursAgo", count: 1))
    #expect(readout != TimeSliderReadout(instant: instant, word: "layers.timeHoursAhead", count: 2))
    #expect(TimeSliderReadout(instant: nil, word: "layers.timeNow", count: nil).count == nil)
    #expect(
      TimeSliderReadout(instant: nil, word: "layers.caf\u{E9}", count: nil)
        != TimeSliderReadout(instant: nil, word: "layers.cafe\u{301}", count: nil),
      "a word is compared by its scalars")
  }
}
