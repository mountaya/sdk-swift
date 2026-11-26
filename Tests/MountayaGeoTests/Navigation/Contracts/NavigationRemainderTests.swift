import Testing

@testable import MountayaGeo

@Suite("NavigationRemainder")
struct NavigationRemainderTests {
  @Test("two remainders are equal where both are the same number, and hash alike")
  func equality() {
    #expect(
      NavigationRemainder(distance: 1_200, duration: 600)
        == NavigationRemainder(distance: 1_200, duration: 600))
    #expect(
      NavigationRemainder(distance: 1_200, duration: 600).hashValue
        == NavigationRemainder(distance: 1_200, duration: 600).hashValue)
    #expect(
      NavigationRemainder(distance: .nan, duration: nil)
        == NavigationRemainder(distance: .nan, duration: nil))
    #expect(
      NavigationRemainder(distance: 0, duration: 0)
        != NavigationRemainder(distance: 0, duration: -0.0))
    #expect(
      NavigationRemainder(distance: 0, duration: 0)
        != NavigationRemainder(distance: 0, duration: nil))
  }
}
