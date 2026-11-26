import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("NavigationInstructionKey")
struct NavigationInstructionKeyTests {
  /// Two keys a maneuver, the waypoint's pair, then the roundabout's exit pair: the closed set a
  /// host's strings fill.
  @Test("every maneuver has its own key and its Plain twin, a waypoint too, then the roundabout's")
  func everyManeuver() {
    let expected =
      (navigationManeuvers + [.waypoint]).flatMap { [$0.rawValue, $0.rawValue + "Plain"] } + [
        "roundaboutExit", "roundaboutExitPlain",
      ]

    #expect(NavigationInstructionKey.allCases.count == 34)
    #expect(NavigationInstructionKey.allCases.map(\.id) == expected.sorted())
  }

  @Test("a key names the arguments it takes, in order")
  func arguments() {
    #expect(NavigationInstructionKey.turnLeft.arguments == [.name])
    #expect(NavigationInstructionKey.turnLeftPlain.arguments == [])
    #expect(NavigationInstructionKey.roundaboutExit.arguments == [.exit, .name])
    #expect(NavigationInstructionKey.roundaboutExitPlain.arguments == [.exit])
    #expect(NavigationInstructionKey.waypoint.arguments == [.name])
    #expect(NavigationInstructionKey.waypointPlain.arguments == [])
    let maneuvers = NavigationInstructionKey.allCases.filter { !$0.id.hasPrefix("roundaboutExit") }
    #expect(maneuvers.map { $0.id.hasSuffix("Plain") } == maneuvers.map(\.arguments.isEmpty))
  }

  /// The ids are the spelling a host's strings are keyed by: REST's kebab-case maneuver, then
  /// `Plain`.
  @Test("a key is spelled as the contract spells it")
  func spelling() {
    #expect(NavigationInstructionKey.enterRoundaboutPlain.id == "enter-roundaboutPlain")
    #expect(NavigationInstructionKey.uturn.id == "uturn")
    #expect(NavigationInstructionKey.roundaboutExitPlain.id == "roundaboutExitPlain")
    #expect(NavigationInstructionKey.continue.id == "continue")
  }
}
