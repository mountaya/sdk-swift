import Testing

@testable import MountayaGeo

@Suite("convertDuration")
struct ConvertDurationTests {
  @Test("each unit holds a whole number of milliseconds")
  func wholeMilliseconds() {
    #expect(convertDuration(1, from: .day, to: .millisecond) == 86_400_000)
    #expect(convertDuration(1, from: .day, to: .hour) == 24)
    #expect(convertDuration(1, from: .hour, to: .second) == 3_600)
    #expect(convertDuration(1, from: .minute, to: .second) == 60)
    #expect(convertDuration(90_000, from: .millisecond, to: .minute) == 1.5)
  }

  @Test("a duration in its own unit is returned as it is")
  func ownUnit() {
    for unit in DurationUnit.allCases {
      #expect(convertDuration(0.1, from: unit, to: unit) == 0.1)
    }
  }
}
