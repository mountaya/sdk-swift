import Testing

@testable import MountayaGeo

@Suite("InfoRange")
struct InfoRangeTests {
  @Test("two ranges are equal when they hold one span and the same value, and hash alike")
  func equality() {
    let range = InfoRange(fromIndex: 0, toIndex: 2, value: "gravel")
    #expect(range == InfoRange(fromIndex: 0, toIndex: 2, value: "gravel"))
    #expect(range.hashValue == InfoRange(fromIndex: 0, toIndex: 2, value: "gravel").hashValue)
    #expect(range != InfoRange(fromIndex: 0, toIndex: 2, value: "asphalt"))
    #expect(range != InfoRange(fromIndex: 0, toIndex: 3, value: "gravel"))
    #expect(
      InfoRange(fromIndex: 0, toIndex: 1, value: Double.nan)
        == InfoRange(fromIndex: 0, toIndex: 1, value: .nan))
    #expect(
      String(describing: range) == "InfoRange<String>(fromIndex: 0, toIndex: 2, value: \"gravel\")")
  }
}
