import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("navigationProgressAt")
struct NavigationProgressAtTests {
  /// East along the equator for two stretches, then north for two: a depart, a turn and the
  /// arrival.
  private let line: [[Double]] = [[0, 0], [0.01, 0], [0.02, 0], [0.02, 0.01], [0.02, 0.02]]
  private var measured: [Double] { cumulativeMeters(line) }

  private func route(_ line: [[Double]], steps: [NavigationStep] = [], duration: Double? = nil)
    throws -> FollowedRoute
  {
    try #require(followedRouteOf(NavigationRoute(line: line, steps: steps, duration: duration)))
  }

  private func turning(departs: Double? = 1_200, turns: Double? = 900, shift: Int = 0)
    -> [NavigationStep]
  {
    [
      NavigationStep(
        fromIndex: 0, toIndex: 2 + shift, maneuver: .depart, name: "Chemin des Praz",
        distance: 2_200, duration: departs),
      NavigationStep(
        fromIndex: 2 + shift, toIndex: 4 + shift, maneuver: .turnLeft,
        name: "Chemin du Lac", distance: 2_200, duration: turns),
      NavigationStep(
        fromIndex: 4 + shift, toIndex: 4 + shift, maneuver: .goal, distance: 0,
        duration: 0),
    ]
  }

  @Test("at the start the whole route is left")
  func atTheStart() throws {
    let progress = navigationProgressAt(
      try route(line, steps: turning()), position: [0, 0], previous: 0)

    #expect(progress.along == 0)
    #expect(progress.step == 0)
    #expect(progress.next == 1)
    #expect(progress.toManeuver == NavigationRemainder(distance: measured[2], duration: 1_200))
    #expect(progress.toArrival == NavigationRemainder(distance: measured[4], duration: 2_100))
  }

  /// A step's own distance is never read: the remainders are lengths of the one line.
  @Test("the time left is the step's own, prorated by its measured length")
  func prorated() throws {
    let progress = navigationProgressAt(
      try route(line, steps: turning()), position: [0.005, 0.0001], previous: 0)

    #expect(isClose(progress.along, 555.9746332227937, within: 1e-6))
    #expect(isClose(progress.toManeuver.distance, measured[2] - progress.along, within: 1e-9))
    #expect(isClose(progress.toManeuver.duration ?? .nan, 900, within: 1e-9))
    #expect(isClose(progress.toArrival.duration ?? .nan, 1_800, within: 1e-9))
    #expect(progress.toArrival.distance >= progress.toManeuver.distance)
  }

  /// The earlier stretch wins a tie, and its far end is exactly where the next stretch starts.
  @Test("on a maneuver's vertex, that maneuver is next, with no distance left to it")
  func onTheVertex() throws {
    let progress = navigationProgressAt(
      try route(line, steps: turning()), position: [0.02, 0], previous: 0)

    #expect(progress.along == measured[2])
    #expect(progress.step == 0)
    #expect(progress.next == 1)
    #expect(progress.toManeuver == NavigationRemainder(distance: 0, duration: 0))
  }

  @Test("a nearer stretch ahead wins, and the step holding it is current")
  func nearerAhead() throws {
    let progress = navigationProgressAt(
      try route(line, steps: turning()), position: [0.0199, 0.005], previous: 0)

    #expect(progress.step == 1)
    #expect(progress.next == 2)
    #expect(isClose(progress.along, 2_779.8731661139686, within: 1e-6))
  }

  @Test("progress never moves back")
  func neverBack() throws {
    let progress = navigationProgressAt(
      try route(line, steps: turning()), position: [0.005, 0], previous: 1_000)

    #expect(progress.along == 1_000)
    #expect(progress.step == 0)
  }

  /// A stretch that ends behind the last progress is never projected onto.
  @Test("the return leg of an out-and-back is not mistaken for the way out")
  func outAndBack() throws {
    let outAndBack: [[Double]] = [[0, 0], [0.01, 0], [0, 0]]
    let there = cumulativeMeters(outAndBack)

    #expect(
      isClose(
        navigationProgressAt(try route(outAndBack), position: [0.005, 0], previous: 0).along,
        there[1] / 2, within: 1e-6))
    #expect(
      isClose(
        navigationProgressAt(try route(outAndBack), position: [0.005, 0], previous: there[1] + 1)
          .along,
        there[1] + (there[2] - there[1]) / 2, within: 1e-6))
  }

  @Test("a loop starts at its start, and ends at its end once come round")
  func loop() throws {
    let loop: [[Double]] = [[0, 0], [0.01, 0], [0.01, 0.01], [0, 0.01], [0, 0]]
    let round = cumulativeMeters(loop)

    #expect(navigationProgressAt(try route(loop), position: [0, 0], previous: 0).along == 0)
    #expect(
      navigationProgressAt(try route(loop), position: [0, 0], previous: 3_000).along == round[4])
    #expect(
      navigationProgressAt(try route(loop, duration: 600), position: [0, 0], previous: 3_000)
        .toArrival == NavigationRemainder(distance: 0, duration: 0))
  }

  /// The last progress is held within the route, and one that is no number reads as none at all.
  @Test("the last progress is held within the route")
  func previousHeld() throws {
    let followed = try route(line, steps: turning())

    #expect(navigationProgressAt(followed, position: [0, 0], previous: .nan).along == 0)
    #expect(navigationProgressAt(followed, position: [0, 0], previous: -5).along == 0)
    #expect(navigationProgressAt(followed, position: [0, 0], previous: 1e9).along == measured[4])
    #expect(
      navigationProgressAt(followed, position: [0, 0], previous: .infinity).along == measured[4])
  }

  @Test("a step that states no duration leaves no time")
  func noDuration() throws {
    let untimed = navigationProgressAt(
      try route(line, steps: turning(departs: nil)), position: [0.005, 0], previous: 0)
    let laterUntimed = navigationProgressAt(
      try route(line, steps: turning(turns: nil)), position: [0.005, 0], previous: 0)

    #expect(untimed.toManeuver.duration == nil)
    #expect(untimed.toArrival.duration == nil)
    #expect(isClose(laterUntimed.toManeuver.duration ?? .nan, 900, within: 1e-9))
    #expect(laterUntimed.toArrival.duration == nil)
  }

  @Test("a route of one vertex stands at its end, in its last step")
  func oneVertex() throws {
    let progress = navigationProgressAt(
      try route([[0, 0]], duration: 0), position: [0.001, 0], previous: 0)

    #expect(progress.along == 0)
    #expect(progress.step == 1)
    #expect(progress.next == nil)
    #expect(progress.toArrival == NavigationRemainder(distance: 0, duration: 0))
  }

  /// As a corridor is measured, and as every walk of a line reads it: the stretch runs from the
  /// vertex before to the vertex after.
  @Test("a vertex that names no place is bridged")
  func bridged() throws {
    let bridged = [line[0], line[1], [.nan, .nan], line[2], line[3], line[4]]
    let plain = navigationProgressAt(
      try route(line, steps: turning()), position: [0.015, 0.0001], previous: 0)
    let read = navigationProgressAt(
      try route(bridged, steps: turning(shift: 1)), position: [0.015, 0.0001], previous: 0)

    #expect(isClose(read.along, plain.along, within: 1e-9))
    #expect(isClose(read.toArrival.distance, plain.toArrival.distance, within: 1e-9))
    #expect(
      isClose(read.toManeuver.duration ?? .nan, plain.toManeuver.duration ?? .nan, within: 1e-9))
    #expect(read.step == 0)
  }

  /// No foot is measured from a place nobody named: every figure it measures is no number, in the
  /// step holding the first stretch ahead of the last progress. An engine refuses such a position
  /// before it reaches here. Swift's `max` would drop the `NaN` taken first.
  @Test("a position that names no place reads no number")
  func noPlace() throws {
    let followed = try route(line, steps: turning())
    let nowhere = navigationProgressAt(followed, position: [.nan, 0], previous: 0)

    #expect(nowhere.along.isNaN)
    #expect(nowhere.toArrival.distance.isNaN)
    #expect(nowhere.toManeuver.duration?.isNaN == true)
    #expect(nowhere.step == 0)
    #expect(navigationProgressAt(followed, position: [.nan, 0], previous: 2_500).step == 1)
    #expect(navigationProgressAt(followed, position: [0], previous: 0).along.isNaN)
  }

  /// The machine reads each position in one pass: the progress is the rule's own, figure for
  /// figure, and the distance is what a corridor measures to the route's line, behind the last
  /// progress included, whatever the line does.
  @Test("one pass reads the progress and the distance to the route each rule answers")
  func onePass() throws {
    let lines: [(line: [[Double]], steps: [NavigationStep])] = [
      (line, turning()),
      ([[0, 0], [0.01, 0], [0, 0]], []),
      ([[0, 0], [0.01, 0], [0.01, 0.01], [0, 0.01], [0, 0]], []),
      ([line[0], line[1], [.nan, .nan], line[2], line[3], line[4]], turning(shift: 1)),
      ([[179.99, 0], [-179.99, 0], [-179.98, 0.01]], []),
      ([[0, 0]], []),
      ([[0, 0, 1_200], [0.01, 0.01, 1_400], [0.01, 0.01], [0.02, 0]], []),
    ]
    let positions: [[Double]] = [
      [0, 0], [0.005, 0.0001], [0.02, 0], [0.0199, 0.005], [0.005, 0.0018], [0.01, 0.005],
      [-179.995, 0.0001], [179.995, -0.0003], [0, 0.01], [0.02, 0.02, 9], [3, 3], [.nan, 0], [0],
    ]
    for (line, steps) in lines {
      let followed = try route(line, steps: steps)
      let total = followed.measured.last ?? 0
      for position in positions {
        for previous in [0, 300, total / 2, total, .nan] {
          let reading = navigationReadingAt(followed, position: position, previous: previous)
          let progress = navigationProgressAt(followed, position: position, previous: previous)
          let meters = metersToRoute(position, lines: [GeoJSONLineString(coordinates: line)])
          let label = "\(position) after \(previous) on \(line)"
          #expect(reading.progress == progress, "\(label)")
          #expect(sameNumber(reading.metersToRoute, meters), "\(label)")
        }
      }
    }
  }
}
