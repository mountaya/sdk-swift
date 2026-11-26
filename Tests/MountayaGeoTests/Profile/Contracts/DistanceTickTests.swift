import Testing

@testable import MountayaGeo

@Suite("DistanceTick")
struct DistanceTickTests {
  @Test("two stops are equal when they hold the same numbers, and hash alike")
  func equality() {
    let tick = DistanceTick(value: 1.2, meters: 1_200, fractionDigits: 1)
    #expect(tick == DistanceTick(value: 1.2, meters: 1_200, fractionDigits: 1))
    #expect(tick.hashValue == DistanceTick(value: 1.2, meters: 1_200, fractionDigits: 1).hashValue)
    #expect(tick != DistanceTick(value: 1.2, meters: 1_200, fractionDigits: 0))
    #expect(
      DistanceTick(value: 0, meters: 0, fractionDigits: 0)
        != DistanceTick(value: -0.0, meters: 0, fractionDigits: 0))
    #expect(
      String(describing: DistanceTick(value: 5, meters: 8_046.72, fractionDigits: 0))
        == "DistanceTick(value: 5.0, meters: 8046.72, fractionDigits: 0)")
  }
}
