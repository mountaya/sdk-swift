import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("resolveWaypoints")
struct ResolveWaypointsTests {
  private let loop = lineString(
    [6.8652, 45.9237], [6.8852, 45.9337], [6.9052, 45.9237], [6.8852, 45.9137], [6.8652, 45.92372])
  private let outAndBack = lineString(
    [6.8652, 45.9237], [6.8752, 45.9237], [6.8852, 45.9237], [6.8952, 45.9287], [6.9052, 45.9237],
    [6.8952, 45.9187], [6.8852, 45.9237], [6.8752, 45.9237], [6.8652, 45.9237])

  private func placed(_ geometry: GeoJSONGeometry, waypoints: ProfileWaypoint...) -> [(
    key: String, distance: Double
  )] {
    resolveWaypoints(geometry, waypoints: waypoints).map { ($0.key, $0.distance) }
  }

  @Test("a loop's start and finish stand at zero and at the total")
  func loopEnds() {
    let result = placed(
      loop, waypoints: .atPosition(id: "start", position: [6.8652, 45.9237]),
      .atPosition(id: "summit", position: [6.9052, 45.9237]),
      .atPosition(id: "finish", position: [6.8652, 45.9237]))
    #expect(result.map(\.key) == ["start#0", "summit#0", "finish#0"])
    #expect(result.first?.distance == 0)
    #expect(isClose(result.last?.distance ?? .nan, 7_620.575694388079, within: 1e-6))
  }

  @Test("a place passed twice and claimed once is marked at each pass")
  func twoPasses() {
    let result = placed(outAndBack, waypoints: .atPosition(id: "hut", position: [6.8752, 45.9237]))
    #expect(result.map(\.key) == ["hut#0", "hut#1"])
    #expect(isClose(result.first?.distance ?? .nan, 773.4893547445723, within: 1e-6))
    #expect(isClose(result.last?.distance ?? .nan, 6_130.75639425873, within: 1e-6))
  }

  @Test("a distance is on the axis already, and one that is no number places nothing")
  func distances() {
    let marker = placed(loop, waypoints: .atDistance(id: "marker", distance: 1_200))
    #expect(marker.map(\.key) == ["marker#0"])
    #expect(marker.map(\.distance) == [1_200])
    #expect(placed(loop, waypoints: .atDistance(id: "marker", distance: .nan)).isEmpty)
  }

  @Test(
    "a place off the line stands at its nearest approach, and one far off or nowhere is not placed")
  func offTheLine() {
    let village = placed(
      outAndBack, waypoints: .atPosition(id: "village", position: [6.8852, 45.9257]))
    #expect(village.count == 1)
    #expect(isClose(village.first?.distance ?? .nan, 1_676.7740764172786, within: 1e-6))
    #expect(
      placed(outAndBack, waypoints: .atPosition(id: "elsewhere", position: [7.5, 46.5])).isEmpty)
    #expect(
      placed(outAndBack, waypoints: .atPosition(id: "nowhere", position: [.nan, 45.9237])).isEmpty)
    #expect(
      resolveWaypoints(nil, waypoints: [.atPosition(id: "hut", position: [6.8752, 45.9237])])
        .isEmpty)
  }

  @Test("a place listed after a later one falls back to its last pass")
  func fallsBack() {
    let result = placed(
      outAndBack, waypoints: .atPosition(id: "turn", position: [6.9052, 45.9237]),
      .atPosition(id: "start", position: [6.8652, 45.9237]),
      .atPosition(id: "fork", position: [6.8752, 45.9237]))
    #expect(result.map(\.key) == ["start#0", "fork#0", "turn#0", "fork#1", "start#1"])
  }

  /// Two waypoints of one id are two waypoints, and their keys count that id's passes across both.
  @Test("two waypoints given one id are two, and their keys stay unique")
  func oneIdTwice() {
    let result = placed(
      loop, waypoints: .atDistance(id: "km", distance: 1_000),
      .atDistance(id: "km", distance: 2_000))
    #expect(result.map(\.key) == ["km#0", "km#1"])
    #expect(result.map(\.distance) == [1_000, 2_000])
    #expect([waypointProximityMeters, waypointBelongingMeters] == [60, 2_000])
  }

  /// Swift's `<` reads -0 and 0 as one; the placements are ordered as Kotlin's `compareTo` orders
  /// them, -0 first.
  @Test("a placement at -0 stands before one at 0, whatever the order they are listed in")
  func totalOrder() {
    let result = placed(
      loop, waypoints: .atDistance(id: "zero", distance: 0),
      .atDistance(id: "negative", distance: -0.0))
    #expect(result.map(\.key) == ["negative#0", "zero#0"])
  }

  @Test("each placement says whether it is its waypoint's primary pass")
  func primaryPasses() {
    let passes = waypointPasses(
      outAndBack, waypoints: [.atPosition(id: "hut", position: [6.8752, 45.9237])])
    #expect(passes.map(\.key) == ["hut#0", "hut#1"])
    #expect(passes.map(\.isPrimary) == [true, false])
    #expect(passes.map(\.listed) == [0, 0])
    let loopPasses = waypointPasses(
      loop,
      waypoints: [
        .atPosition(id: "start", position: [6.8652, 45.9237]),
        .atPosition(id: "summit", position: [6.9052, 45.9237]),
        .atPosition(id: "finish", position: [6.8652, 45.9237]),
      ])
    #expect(loopPasses.map(\.key) == ["start#0", "summit#0", "finish#0"])
    #expect(loopPasses.map(\.isPrimary) == [true, true, true])
    #expect(loopPasses.map(\.listed) == [0, 1, 2])
  }
}
