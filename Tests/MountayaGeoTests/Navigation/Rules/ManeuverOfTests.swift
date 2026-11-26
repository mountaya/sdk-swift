import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("maneuverOf")
struct ManeuverOfTests {
  private let unknown = RestSchema.ManeuverType.unknown

  @Test("the vocabulary is REST's fifteen members, in the order of their values")
  func vocabulary() {
    #expect(navigationManeuvers.count == 15)
    #expect(navigationManeuvers.map(\.rawValue) == navigationManeuvers.map(\.rawValue).sorted())
  }

  /// A value REST does not spell is said as one this build knows, never dropped: a member the API
  /// added since, and the Data API's spelling, alike. Matched exactly, letter case included.
  @Test("a REST maneuver is read as written, and any other as unknown")
  func rest() {
    #expect(maneuverOf(RestSchema.ManeuverType(rawValue: "turn-left")) == .turnLeft)
    #expect(maneuverOf(RestSchema.ManeuverType(rawValue: "merge")) == unknown)
    #expect(maneuverOf(RestSchema.ManeuverType(rawValue: "TURN_LEFT")) == unknown)
    #expect(maneuverOf(RestSchema.ManeuverType(rawValue: "Turn-Left")) == unknown)
    #expect(maneuverOf(RestSchema.ManeuverType(rawValue: " turn-left")) == unknown)
    #expect(maneuverOf(RestSchema.ManeuverType(rawValue: "unknown")) == unknown)
  }

  /// The contract's transform, held to every constant the generated Data API vocabulary prints.
  @Test("a Data API maneuver is read as its REST member")
  func data() {
    let data: [DataSchema.ManeuverType] = [
      .continue, .depart, .enterRoundabout, .exitRoundabout, .goal, .keepLeft, .keepRight,
      .sharpLeft, .sharpRight, .slightLeft, .slightRight, .turnLeft, .turnRight, .unknown,
      .uturn,
    ]

    #expect(data.map(dataManeuverOf) == navigationManeuvers)
  }

  @Test("a Data API maneuver it does not spell, or does not state, is unknown")
  func dataUnknown() {
    #expect(dataManeuverOf(DataSchema.ManeuverType(rawValue: "turn-left")) == unknown)
    #expect(dataManeuverOf(DataSchema.ManeuverType(rawValue: "MERGE")) == unknown)
    #expect(dataManeuverOf(DataSchema.ManeuverType(rawValue: "Turn_Left")) == unknown)
    #expect(dataManeuverOf(nil) == unknown)
  }

  /// A dictionary finds `KEEP_LEFT` under a Kelvin sign, U+212A, which is canonically a `K`: the
  /// spelling is held to its scalars, as the other SDKs compare code points.
  @Test("a spelling canonically equivalent to a member is another spelling")
  func canonicalEquivalence() {
    #expect("\u{212A}EEP_LEFT" == "KEEP_LEFT")
    #expect(dataManeuverOf(DataSchema.ManeuverType(rawValue: "\u{212A}EEP_LEFT")) == unknown)
    #expect(maneuverOf(RestSchema.ManeuverType(rawValue: "\u{212A}eep-left")) == unknown)
  }
}
