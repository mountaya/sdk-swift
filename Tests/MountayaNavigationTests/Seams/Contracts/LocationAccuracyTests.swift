import Testing

@testable import MountayaNavigation

@Suite("LocationAccuracy")
struct LocationAccuracyTests {
  @Test("an accuracy is full or reduced")
  func cases() {
    #expect(LocationAccuracy.allCases == [.full, .reduced])
  }
}
