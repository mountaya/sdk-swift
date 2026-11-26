import Testing

@testable import MountayaGeo

@Suite("TimeLength")
struct TimeLengthTests {
  @Test("the lengths run from the shorter to the longer, and stop before the zone's")
  func order() {
    #expect(TimeLength.allCases == [.short, .medium])
  }

  @Test("each length is named as the contract names it")
  func names() {
    #expect(TimeLength.allCases.map(\.rawValue) == ["short", "medium"])
    #expect(TimeLength(rawValue: "long") == nil)
    #expect(TimeLength(rawValue: "full") == nil)
  }
}
