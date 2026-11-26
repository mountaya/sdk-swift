import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("enabledTargets")
struct EnabledTargetsTests {
  @Test("a request enables its branch alone, every other flag stated false")
  func alone() throws {
    let known: [DataSchema.SearchTarget] = [
      .places, .pois, .ways, .itineraries, .collections, .zones,
    ]
    for (index, branch) in known.enumerated() {
      let targets = try #require(enabledTargets(branch))
      let flags = [
        targets.places, targets.pois, targets.ways, targets.itineraries, targets.collections,
        targets.zones,
      ]
      #expect(flags == (0..<6).map { $0 == index })
    }
  }

  @Test("a branch this build cannot enable enables nothing, its name read by its scalars")
  func unknown() {
    #expect(enabledTargets(DataSchema.SearchTarget(rawValue: "TRAILS")) == nil)
    #expect(enabledTargets(DataSchema.SearchTarget(rawValue: "places")) == nil)
    #expect(enabledTargets(DataSchema.SearchTarget(rawValue: "")) == nil)
  }
}
