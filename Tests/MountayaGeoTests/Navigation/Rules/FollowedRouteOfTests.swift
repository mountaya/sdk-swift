import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("followedRouteOf")
struct FollowedRouteOfTests {
  private let line: [[Double]] = [[6.8652, 45.9237], [6.8752, 45.9287], [6.9271, 45.9682]]

  @Test("a route with no steps departs over its whole line, and arrives on its last vertex")
  func departsAndArrives() {
    let followed = followedRouteOf(NavigationRoute(line: line, duration: 6_300))

    #expect(
      followed?.steps == [
        NavigationStep(
          fromIndex: 0, toIndex: 2, maneuver: .depart,
          distance: routeLengthMeters(line), duration: 6_300),
        NavigationStep(
          fromIndex: 2, toIndex: 2, maneuver: .goal, distance: 0, duration: 0),
      ])
    #expect(followed?.line == line)
  }

  /// A measurement is a haversine per vertex of the whole line: the departure's length is the last
  /// figure of the measure the route holds, never a second walk of the line.
  @Test("a route is measured once as it is followed, with steps of its own or none")
  func measuredOnce() throws {
    let probe = MeasureProbe()
    let steps = [
      NavigationStep(fromIndex: 0, toIndex: 2, maneuver: .depart, distance: 9_000),
      NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal, distance: 0),
    ]

    let followed = try MeasureProbe.$current.withValue(probe) {
      (
        stepless: try #require(followedRouteOf(NavigationRoute(line: line, duration: 6_300))),
        stepped: try #require(followedRouteOf(NavigationRoute(line: line, steps: steps)))
      )
    }

    #expect(probe.lines == [line, line])
    #expect(followed.stepless.measured == cumulativeMeters(line))
    #expect(followed.stepless.steps.first?.distance == followed.stepless.measured.last)
    #expect(followed.stepped.measured == cumulativeMeters(line))
  }

  @Test("a route that states no duration departs with none")
  func noDuration() {
    #expect(followedRouteOf(NavigationRoute(line: line))?.steps.first?.duration == nil)
  }

  @Test("a route with steps that tile its line is followed by them, unchanged")
  func followedBySteps() {
    let steps = [
      NavigationStep(
        fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Route des Chavants",
        distance: 8_400, duration: 7_200),
      NavigationStep(
        fromIndex: 1, toIndex: 2, maneuver: .goal, distance: 9_000, duration: 7_560),
    ]

    #expect(
      followedRouteOf(NavigationRoute(line: line, steps: steps, duration: 14_760))?.steps == steps)
  }

  /// A list a host wrote by hand is held to the tiling rule too, and is refused rather than
  /// repaired.
  @Test("steps that do not tile the line are refused, and the route departs and arrives")
  func refusedSteps() {
    let broken = [
      NavigationStep(
        fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Route des Chavants")
    ]
    let followed = followedRouteOf(NavigationRoute(line: line, steps: broken, duration: 600))

    #expect(followed?.steps.map(\.maneuver) == [.depart, .goal])
    #expect(followed?.steps.first?.name == nil)
  }

  @Test("a route of one vertex departs and arrives on it")
  func oneVertex() {
    let followed = followedRouteOf(NavigationRoute(line: [[6.8652, 45.9237]], duration: 0))

    #expect(
      followed?.steps == [
        NavigationStep(
          fromIndex: 0, toIndex: 0, maneuver: .depart, distance: 0, duration: 0),
        NavigationStep(
          fromIndex: 0, toIndex: 0, maneuver: .goal, distance: 0, duration: 0),
      ])
  }

  @Test("a route of no vertex is not followed")
  func noVertex() {
    #expect(followedRouteOf(NavigationRoute(line: [], duration: 600)) == nil)
  }

  /// The departure's length is the line's as every walk of it reads it, a vertex naming no place
  /// bridged.
  @Test("the departure's length bridges a vertex that names no place")
  func bridged() {
    let bridged = [line[0], [.nan, 45], line[2]]

    #expect(
      followedRouteOf(NavigationRoute(line: bridged))?.steps.first?.distance
        == routeLengthMeters([line[0], line[2]]))
  }
}
