import Testing

@testable import MountayaGeo

@Suite("DurationSplit")
struct DurationSplitTests {
  @Test("two splits are equal when they hold the same hours and minutes, and hash alike")
  func equality() {
    #expect(DurationSplit(hours: 2, minutes: 35) == DurationSplit(hours: 2, minutes: 35))
    #expect(
      DurationSplit(hours: 2, minutes: 35).hashValue
        == DurationSplit(hours: 2, minutes: 35).hashValue)
    #expect(DurationSplit(hours: 2, minutes: 35) != DurationSplit(hours: 35, minutes: 2))
    #expect(
      String(describing: DurationSplit(hours: 2, minutes: 35))
        == "DurationSplit(hours: 2, minutes: 35)")
  }
}
