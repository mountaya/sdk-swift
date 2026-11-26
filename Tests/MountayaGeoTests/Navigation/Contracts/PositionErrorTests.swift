import Testing

@testable import MountayaGeo

@Suite("PositionError")
struct PositionErrorTests {
  @Test("a refused position is named as it was stated")
  func named() {
    let refusal = PositionError(position: [.nan, 45])

    #expect(refusal.position.count == 2)
    #expect(refusal.position[0].isNaN)
    #expect(
      refusal.description
        == "NavigationEngine.setPosition: position is [nan, 45.0]; pass a [longitude, latitude] of "
        + "two finite numbers, in degrees.")
  }
}
