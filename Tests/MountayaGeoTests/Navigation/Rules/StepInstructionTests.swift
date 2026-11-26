import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("stepInstruction")
struct StepInstructionTests {
  private func said(_ maneuver: String, name: String?, exit: Int? = nil) -> NavigationInstruction {
    stepInstruction(
      NavigationStep(
        fromIndex: 0, toIndex: 1, maneuver: RestSchema.ManeuverType(rawValue: maneuver),
        name: name, exitNumber: exit))
  }

  @Test("a maneuver is said with its own key onto a named way, and its Plain twin where none is")
  func ownKeyAndPlain() {
    for maneuver in navigationManeuvers {
      #expect(said(maneuver.rawValue, name: "Rue du Docteur Paccard").key.id == maneuver.rawValue)
      #expect(
        said(maneuver.rawValue, name: "Rue du Docteur Paccard").name == "Rue du Docteur Paccard")
      #expect(said(maneuver.rawValue, name: nil).key.id == maneuver.rawValue + "Plain")
      let plain = said(maneuver.rawValue, name: nil)
      #expect(plain == NavigationInstruction(key: plain.key))
    }
  }

  /// The exit is what a traveller needs at a roundabout, so it is said there, entered or left.
  @Test("a roundabout naming an exit is said with the exit")
  func roundaboutExit() {
    #expect(
      said("enter-roundabout", name: "Avenue Michel Croz", exit: 2)
        == NavigationInstruction(key: .roundaboutExit, name: "Avenue Michel Croz", exit: 2))
    #expect(
      said("enter-roundabout", name: nil, exit: 3)
        == NavigationInstruction(key: .roundaboutExitPlain, exit: 3))
    #expect(
      said("exit-roundabout", name: "-", exit: 1)
        == NavigationInstruction(key: .roundaboutExitPlain, exit: 1))
  }

  @Test("an exit of zero or less, or away from a roundabout, names nothing")
  func exitNamesNothing() {
    #expect(
      said("enter-roundabout", name: "Avenue Michel Croz", exit: 0)
        == NavigationInstruction(key: .enterRoundabout, name: "Avenue Michel Croz"))
    #expect(
      said("exit-roundabout", name: nil, exit: -1)
        == NavigationInstruction(key: .exitRoundaboutPlain))
    #expect(
      said("turn-right", name: "Rue du Docteur Paccard", exit: 2)
        == NavigationInstruction(key: .turnRight, name: "Rue du Docteur Paccard"))
  }

  @Test("an empty name and the API's dash are no name, and any other is one")
  func names() {
    #expect(said("turn-left", name: "").key == .turnLeftPlain)
    #expect(said("turn-left", name: "-").key == .turnLeftPlain)
    #expect(said("turn-left", name: " ") == NavigationInstruction(key: .turnLeft, name: " "))
  }

  /// A maneuver the API adds after this build, or another surface's spelling, is said as
  /// `unknown`.
  @Test("a waypoint is said by its name, or plain where it has none, whatever exit it states")
  func waypoint() {
    #expect(
      said("waypoint", name: "Refuge de Bellachat")
        == NavigationInstruction(key: .waypoint, name: "Refuge de Bellachat"))
    #expect(said("waypoint", name: nil) == NavigationInstruction(key: .waypointPlain))
    #expect(said("waypoint", name: "-") == NavigationInstruction(key: .waypointPlain))
    #expect(said("waypoint", name: nil, exit: 2) == NavigationInstruction(key: .waypointPlain))
    // Spelled with another letter case, it is no member of the vocabulary.
    #expect(
      said("Waypoint", name: "Refuge") == NavigationInstruction(key: .unknown, name: "Refuge"))
  }

  @Test("a maneuver outside the vocabulary is said as unknown")
  func outsideTheVocabulary() {
    #expect(
      said("merge", name: "Route Blanche")
        == NavigationInstruction(key: .unknown, name: "Route Blanche"))
    #expect(said("TURN_LEFT", name: nil) == NavigationInstruction(key: .unknownPlain))
    #expect(
      said("ENTER_ROUNDABOUT", name: nil, exit: 2) == NavigationInstruction(key: .unknownPlain))
  }
}
