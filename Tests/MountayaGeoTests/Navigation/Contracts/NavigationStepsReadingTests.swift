import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("NavigationStepsReading")
struct NavigationStepsReadingTests {
  private let steps = [NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart)]

  @Test("two readings are equal where both members are, and hash alike")
  func equality() {
    #expect(
      NavigationStepsReading(refused: false, steps: steps)
        == NavigationStepsReading(refused: false, steps: steps))
    #expect(
      NavigationStepsReading(refused: false, steps: steps).hashValue
        == NavigationStepsReading(refused: false, steps: steps).hashValue)
    #expect(
      NavigationStepsReading(refused: true, steps: [])
        != NavigationStepsReading(refused: false, steps: []))
  }
}
