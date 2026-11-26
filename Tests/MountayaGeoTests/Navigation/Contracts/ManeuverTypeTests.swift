import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ManeuverType")
struct ManeuverTypeTests {
  @Test("a waypoint is the vocabulary's own, and a surface that writes one is read as unknown")
  func waypoint() {
    #expect(RestSchema.ManeuverType.waypoint.rawValue == "waypoint")
    #expect(!navigationManeuvers.contains(.waypoint))
    #expect(maneuverOf(.waypoint) == .unknown)
    #expect(dataManeuverOf(DataSchema.ManeuverType(rawValue: "WAYPOINT")) == .unknown)
  }
}
