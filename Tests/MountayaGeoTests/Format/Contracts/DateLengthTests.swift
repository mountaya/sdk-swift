import Testing

@testable import MountayaGeo

@Suite("DateLength")
struct DateLengthTests {
  @Test("the lengths run from the shortest to the fullest")
  func order() {
    #expect(DateLength.allCases == [.short, .medium, .long, .full])
  }
}
