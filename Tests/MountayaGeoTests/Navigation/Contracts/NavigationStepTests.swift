import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("NavigationStep")
struct NavigationStepTests {
  private let turn = RestSchema.ManeuverType.turnLeft

  @Test("two steps are equal where every member is the same number, and hash alike")
  func equality() {
    let step = NavigationStep(
      fromIndex: 0, toIndex: 2, maneuver: turn, name: "Chemin du Lac", distance: 900,
      duration: 600)

    #expect(
      step
        == NavigationStep(
          fromIndex: 0, toIndex: 2, maneuver: turn, name: "Chemin du Lac", distance: 900,
          duration: 600))
    #expect(
      step.hashValue
        == NavigationStep(
          fromIndex: 0, toIndex: 2, maneuver: turn, name: "Chemin du Lac", distance: 900,
          duration: 600
        ).hashValue)
    #expect(
      NavigationStep(fromIndex: 0, toIndex: 1, maneuver: turn, duration: .nan)
        == NavigationStep(fromIndex: 0, toIndex: 1, maneuver: turn, duration: .nan))
    #expect(
      NavigationStep(fromIndex: 0, toIndex: 1, maneuver: turn, distance: 0)
        != NavigationStep(fromIndex: 0, toIndex: 1, maneuver: turn, distance: -0.0))
    #expect(
      step
        != NavigationStep(fromIndex: 0, toIndex: 2, maneuver: turn, distance: 900, duration: 600))
    #expect(
      step
        != NavigationStep(
          fromIndex: 0, toIndex: 2, maneuver: turn, name: "Chemin du Lac", distance: 900,
          duration: 600, exitNumber: 2))
  }

  /// A name and a maneuver are compared as they are written, never by canonical equivalence.
  @Test("two steps are told apart by the scalars of their texts")
  func scalars() {
    #expect(
      NavigationStep(fromIndex: 0, toIndex: 1, maneuver: turn, name: "Pr\u{E9}")
        != NavigationStep(fromIndex: 0, toIndex: 1, maneuver: turn, name: "Pre\u{301}"))
    #expect(
      NavigationStep(fromIndex: 0, toIndex: 1, maneuver: RestSchema.ManeuverType(rawValue: "K"))
        != NavigationStep(
          fromIndex: 0, toIndex: 1, maneuver: RestSchema.ManeuverType(rawValue: "\u{212A}")))
  }

  /// A figure nobody stated is none, never a zero.
  @Test("a step states only its range and its maneuver")
  func onlyItsRange() {
    let step = NavigationStep(fromIndex: 3, toIndex: 3, maneuver: .goal)

    #expect(step.name == nil)
    #expect(step.distance == nil)
    #expect(step.duration == nil)
    #expect(step.exitNumber == nil)
  }
}
