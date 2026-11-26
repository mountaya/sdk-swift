import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("TimeSliderTick")
struct TimeSliderTickTests {
  @Test("two ticks are equal where they stand at one stop and carry one word, by its scalars")
  func equality() {
    let now = TimeSliderTick(value: 71, word: "layers.timeNow")

    #expect(now == TimeSliderTick(value: 71, word: "layers.timeNow"))
    #expect(now != TimeSliderTick(value: 47, word: "layers.timeNow"))
    #expect(now != TimeSliderTick(value: 71, word: nil))
    #expect(TimeSliderTick(value: 1, word: "\u{E9}") != TimeSliderTick(value: 1, word: "e\u{301}"))
  }
}
