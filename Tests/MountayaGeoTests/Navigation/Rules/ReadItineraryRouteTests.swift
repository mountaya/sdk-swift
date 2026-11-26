import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("readItineraryRoute")
struct ReadItineraryRouteTests {
  /// step is a step as REST writes one.
  private static func step(
    _ type: RestSchema.ManeuverType, from: Int, to: Int, name: String = "-",
    distance: Double = 100, duration: Double = 60
  ) -> RestSchema.ItineraryDirectionsStep {
    RestSchema.ItineraryDirectionsStep(
      distance: distance, duration: duration, exit_number: nil, from_index: from, name: name,
      to_index: to, type: type)
  }

  /// segment is a directions segment over `positions`, at `position` in the chain.
  private static func segment(
    _ id: String, at position: Int, positions: [[Double]],
    steps: [RestSchema.ItineraryDirectionsStep]? = nil, duration: Double? = 600
  ) -> RestSchema.ItinerarySegment {
    var segment = restSegment(
      id, position: position, geojson: .lineString(GeoJSONLineString(coordinates: positions)),
      duration: duration)
    segment.steps = steps
    return segment
  }

  /// waypoint is a waypoint named `name` standing at `place`.
  private static func waypoint(_ name: String?, at place: [Double], position: Int = 0)
    -> RestSchema.ItineraryWaypoint
  {
    var waypoint = restWaypoint()
    waypoint.name = name
    waypoint.position = position
    waypoint.geojson = .point(GeoJSONPoint(coordinates: place))
    return waypoint
  }

  private static let first: [[Double]] = [
    [6.8652, 45.9237], [6.8752, 45.9287], [6.8852, 45.9337],
  ]
  private static let second: [[Double]] = [
    [6.8852, 45.9337], [6.8952, 45.9387], [6.9052, 45.9437],
  ]

  @Test("an arrival before another segment is a waypoint named where it ends, the last an arrival")
  func waypointBetweenSegments() throws {
    let route = try #require(
      readItineraryRoute(
        [
          Self.segment(
            "b", at: 1, positions: Self.second,
            steps: [
              Self.step(.depart, from: 0, to: 1, name: "Chemin du Lac"),
              Self.step(.turnRight, from: 1, to: 2),
              Self.step(.goal, from: 2, to: 2, distance: 0, duration: 0),
            ], duration: 700),
          Self.segment(
            "a", at: 0, positions: Self.first,
            steps: [
              Self.step(.depart, from: 0, to: 1),
              Self.step(.turnLeft, from: 1, to: 2, name: "Chemin du Lac"),
              Self.step(.goal, from: 2, to: 2, distance: 0, duration: 0),
            ], duration: 500),
        ],
        waypoints: [
          Self.waypoint("Too far", at: [6.8852, 45.94]),
          Self.waypoint("Refuge de Bellachat", at: [6.8853, 45.9337]),
          Self.waypoint("", at: [6.8852, 45.9337]),
        ]))

    #expect(route.line == Self.first + Self.second.dropFirst())
    #expect(route.duration == 1200)
    #expect(
      route.steps.map { "\($0.maneuver.rawValue) \($0.fromIndex)-\($0.toIndex) \($0.name ?? "")" }
        == [
          "depart 0-1 ", "turn-left 1-2 Chemin du Lac", "waypoint 2-2 Refuge de Bellachat",
          "depart 2-3 Chemin du Lac", "turn-right 3-4 ", "goal 4-4 ",
        ])
  }

  @Test("a departure naming no way after a waypoint is folded into it, its figures summed")
  func foldedDeparture() throws {
    let route = try #require(
      readItineraryRoute(
        [
          Self.segment("a", at: 0, positions: Self.first),
          Self.segment(
            "b", at: 1, positions: Self.second,
            steps: [
              Self.step(.depart, from: 0, to: 1, distance: 910, duration: 655),
              Self.step(.turnRight, from: 1, to: 2),
              Self.step(.goal, from: 2, to: 2, distance: 0, duration: 0),
            ]),
        ],
        waypoints: []))

    // The first segment has no steps of its own: a departure, then an arrival said as a waypoint.
    #expect(route.steps.map(\.maneuver) == [.depart, .waypoint, .turnRight, .goal])
    let waypoint = route.steps[1]
    #expect(waypoint.fromIndex == 2 && waypoint.toIndex == 3)
    #expect(waypoint.distance == 910 && waypoint.duration == 655)
    #expect(waypoint.name == nil)
  }

  @Test("a line that starts away from the one before reaches back across the gap")
  func gap() throws {
    let away = [[6.89, 45.94], [6.8952, 45.9387], [6.9052, 45.9437]]
    let route = try #require(
      readItineraryRoute(
        [
          Self.segment("a", at: 0, positions: Self.first),
          Self.segment(
            "b", at: 1, positions: away,
            steps: [
              Self.step(.depart, from: 0, to: 1, name: "Route Blanche"),
              Self.step(.turnRight, from: 1, to: 2),
              Self.step(.goal, from: 2, to: 2, distance: 0, duration: 0),
            ]),
        ],
        waypoints: []))

    #expect(route.line.count == 6)
    #expect(route.steps.map(\.fromIndex) == [0, 2, 2, 4, 5])
    #expect(route.steps.map(\.toIndex) == [2, 2, 4, 5, 5])
    #expect(stepsTile(route.steps, coordinateCount: route.line.count))
  }

  @Test("segments at one position keep the order they are listed in, however many there are")
  func stableChain() throws {
    let segments = (0..<34).map { index in
      Self.segment(
        "s\(index)", at: index / 2,
        positions: [[6.0 + Double(index) * 0.001, 45.0], [6.0 + Double(index + 1) * 0.001, 45.0]])
    }
    let listed = try #require(readItineraryRoute(segments, waypoints: []))
    let reversed = try #require(readItineraryRoute(segments.reversed(), waypoints: []))

    // In the listed order every line starts where the one before ends: one vertex per joint.
    #expect(listed.line.count == 35)
    #expect(listed.line.first == [6.0, 45.0])
    // Reversed, each pair at one position is listed the other way round, and is joined so.
    #expect(reversed.line.first == [6.001, 45.0])
    #expect(stepsTile(reversed.steps, coordinateCount: reversed.line.count))
  }

  @Test(
    "a duration is unknown where a segment holding a line states none, and one holding none is passed over"
  )
  func durations() throws {
    var lineless = Self.segment("x", at: 1, positions: [])
    lineless.duration = nil
    let known = try #require(
      readItineraryRoute(
        [
          Self.segment("a", at: 0, positions: Self.first, duration: 300), lineless,
          Self.segment("b", at: 2, positions: Self.second, duration: 400),
        ],
        waypoints: []))
    #expect(known.duration == 700)

    let unknown = try #require(
      readItineraryRoute(
        [
          Self.segment("a", at: 0, positions: Self.first, duration: nil),
          Self.segment("b", at: 1, positions: Self.second),
        ],
        waypoints: []))
    #expect(unknown.duration == nil)
  }

  @Test("an itinerary none of whose segments holds a line is no route")
  func noLine() {
    var multi = Self.segment("m", at: 0, positions: [])
    multi.geojson = .multiLineString(GeoJSONMultiLineString(coordinates: [Self.first]))
    #expect(
      readItineraryRoute([multi, Self.segment("e", at: 1, positions: [])], waypoints: []) == nil)
    #expect(readItineraryRoute([], waypoints: []) == nil)
  }
}
