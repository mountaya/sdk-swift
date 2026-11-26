import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("guidancePlanOf")
struct GuidancePlanOfTests {
  private func plan(_ route: NavigationRoute) throws -> GuidancePlan {
    let followed = try #require(followedRouteOf(route))
    return try #require(guidancePlanOf(followed))
  }

  @Test("a route with no steps departs over its whole line, then announces the arrival")
  func stepless() throws {
    let line: [[Double]] = [[0, 0], [0.01, 0], [0.02, 0]]
    let length = routeLengthMeters(line)
    let laid = try plan(NavigationRoute(line: line, duration: 1_200))

    #expect(laid.steps.count == 2)
    #expect(laid.steps[0].meters == length)
    #expect(laid.steps[0].instruction.key == .departPlain)
    #expect(laid.steps[0].prompts.map(\.id) == [0, 1])
    #expect(laid.steps[0].prompts.map(\.instruction.key) == [.departPlain, .goalPlain])
    #expect(laid.steps[0].prompts.map(\.meters) == [length, promptMeters])
    #expect(laid.steps[1].meters == 0)
    #expect(laid.steps[1].prompts.isEmpty, "the last step leads to no maneuver")
  }

  @Test("each step announces the maneuver that ends it, the farthest prompt first")
  func eachManeuverAnnounced() throws {
    let line: [[Double]] = [[0, 0], [0.0002, 0], [0.0002, 0.005], [0.0002, 0.01]]
    let route = NavigationRoute(
      line: line,
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Chemin"),
        NavigationStep(
          fromIndex: 1, toIndex: 3, maneuver: .turnLeft, name: "Sentier",
          duration: 300),
        NavigationStep(fromIndex: 3, toIndex: 3, maneuver: .goal),
      ])
    let measured = cumulativeMeters(line)
    let laid = try plan(route)

    #expect(laid.steps.map(\.meters) == [measured[1], measured[3] - measured[1], 0])
    #expect(laid.steps.map(\.instruction.key) == [.depart, .turnLeft, .goalPlain])
    // The first step is 22 m, shorter than the prompt's lead: the turn is said as it begins.
    #expect(laid.steps[0].prompts.map(\.meters) == [measured[1], measured[1]])
    #expect(laid.steps[0].prompts.map(\.instruction.name) == ["Chemin", "Sentier"])
    #expect(laid.steps[1].prompts.map(\.meters) == [promptMeters])
    #expect(laid.steps[1].prompts.map(\.instruction.key) == [.goalPlain])
    #expect(laid.steps.flatMap(\.prompts).map(\.id) == [0, 1, 2])
  }

  /// The route was measured once as it was followed; the plan reads that measure, and every length
  /// it lays out is the one Geo's progress reads the traveller by.
  @Test(
    "every length is read off the route's own measure, which the line is not measured again for")
  func routesOwnMeasure() throws {
    let followed = try #require(
      followedRouteOf(
        NavigationRoute(
          line: [[0, 0], [0.0002, 0], [.nan, 0], [0.0002, 0.005], [0.0002, 0.01]],
          steps: [
            NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart),
            NavigationStep(fromIndex: 1, toIndex: 4, maneuver: .turnLeft),
            NavigationStep(fromIndex: 4, toIndex: 4, maneuver: .goal),
          ])))
    let laid = try #require(guidancePlanOf(followed))
    let measured = followed.measured

    #expect(measured == cumulativeMeters(followed.line))
    #expect(laid.steps.map(\.meters) == [measured[1], measured[4] - measured[1], 0])
    #expect(laid.steps[0].prompts.map(\.meters) == [measured[1], measured[1]])
  }

  @Test("a vertex that names no place is bridged, and an altitude is not read")
  func placelessVertex() throws {
    let laid = try plan(NavigationRoute(line: [[0, 0, 120], [.nan, 0], [0.01, 0, 150]]))

    #expect(laid.steps[0].meters == haversineMeters(from: [0, 0], to: [0.01, 0]))
  }

  /// The two opening steps cover no ground, though Geo's progress may name the first: their
  /// maneuvers move to the step of length, as it begins, and the departure is dropped.
  @Test("a stretch with no vertex that names a place takes no length, nor any prompt")
  func placelessStretch() throws {
    let route = NavigationRoute(
      line: [[0, 0], [.nan, .nan], [.nan, .nan], [0.01, 0]],
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart),
        NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .continue),
        NavigationStep(fromIndex: 2, toIndex: 3, maneuver: .turnRight),
        NavigationStep(fromIndex: 3, toIndex: 3, maneuver: .goal),
      ])
    let laid = try plan(route)
    let length = haversineMeters(from: [0, 0], to: [0.01, 0])

    #expect(laid.steps.map(\.meters) == [0, 0, length, 0])
    #expect(laid.steps.map(\.prompts.isEmpty) == [true, true, false, true])
    #expect(
      laid.steps[2].prompts.map(\.instruction.key) == [.continuePlain, .turnRightPlain, .goalPlain])
    #expect(laid.steps[2].prompts.map(\.meters) == [length, length, promptMeters])
    #expect(laid.steps.flatMap(\.prompts).map(\.id) == [0, 1, 2])
  }

  @Test("a maneuver after a step of no length is announced as the step of length before it ends")
  func zeroLengthStepMidRoute() throws {
    let line: [[Double]] = [[0, 0], [0.01, 0], [0.01, 0.01]]
    let route = NavigationRoute(
      line: line,
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Chemin"),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .turnLeft, name: "Pont"),
        NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .turnRight, name: "Sentier"),
        NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal),
      ])
    let measured = cumulativeMeters(line)
    let laid = try plan(route)

    #expect(laid.steps.map(\.meters) == [measured[1], 0, measured[2] - measured[1], 0])
    #expect(laid.steps[0].prompts.map(\.instruction.key) == [.depart, .turnLeft, .turnRight])
    #expect(laid.steps[0].prompts.map(\.meters) == [measured[1], promptMeters, 0])
    #expect(laid.steps[1].prompts.isEmpty, "a step of no length keeps no prompt")
    #expect(laid.steps[2].prompts.map(\.instruction.key) == [.goalPlain])
    #expect(laid.steps.flatMap(\.prompts).map(\.id) == [0, 1, 2, 3])
  }

  @Test("steps of no length in a row each move after the one before, all due at the vertex")
  func consecutiveZeroLengthSteps() throws {
    let line: [[Double]] = [[0, 0], [0.01, 0], [0.01, 0.01]]
    let route = NavigationRoute(
      line: line,
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .depart),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .turnLeft),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .turnRight),
        NavigationStep(fromIndex: 1, toIndex: 2, maneuver: .continue),
        NavigationStep(fromIndex: 2, toIndex: 2, maneuver: .goal),
      ])
    let measured = cumulativeMeters(line)
    let laid = try plan(route)

    #expect(
      laid.steps[0].prompts.map(\.instruction.key) == [
        .departPlain, .turnLeftPlain, .turnRightPlain, .continuePlain,
      ])
    #expect(laid.steps[0].prompts.map(\.meters) == [measured[1], promptMeters, 0, 0])
    #expect(laid.steps[1].prompts.isEmpty && laid.steps[2].prompts.isEmpty)
    #expect(laid.steps[3].prompts.map(\.instruction.key) == [.goalPlain])
    #expect(laid.steps.flatMap(\.prompts).map(\.id) == [0, 1, 2, 3, 4])
  }

  @Test("a route opening with a step of no length drops its departure, and says what follows it")
  func zeroLengthFirstStep() throws {
    let line: [[Double]] = [[0, 0], [0, 0.01]]
    let route = NavigationRoute(
      line: line,
      steps: [
        NavigationStep(fromIndex: 0, toIndex: 0, maneuver: .depart, name: "Chemin"),
        NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .turnLeft, name: "Sentier"),
        NavigationStep(fromIndex: 1, toIndex: 1, maneuver: .goal),
      ])
    let length = routeLengthMeters(line)
    let laid = try plan(route)

    #expect(laid.steps[0].prompts.isEmpty, "the departure covers no ground and is dropped")
    #expect(laid.steps[1].prompts.map(\.instruction.key) == [.turnLeft, .goalPlain])
    #expect(laid.steps[1].prompts.map(\.meters) == [length, promptMeters])
    #expect(laid.steps.flatMap(\.prompts).map(\.id) == [0, 1])
  }

  @Test(
    "a route of one vertex is laid out at no length, and one whose vertices name no place has none")
  func degenerate() throws {
    let single = try plan(NavigationRoute(line: [[6.8652, 45.9237]]))
    #expect(!single.steps.isEmpty)
    #expect(single.steps.allSatisfy { $0.meters == 0 })
    #expect(
      single.steps[0].prompts.map(\.instruction.key) == [.departPlain, .goalPlain],
      "with no step of length, every prompt stays where it is laid")
    #expect(single.steps.flatMap(\.prompts).map(\.id) == [0, 1])

    let placeless = try #require(followedRouteOf(NavigationRoute(line: [[.nan, 1], [2]])))
    #expect(guidancePlanOf(placeless) == nil)
  }

  @Test("the prompt's lead is fifty meters")
  func lead() {
    #expect(promptMeters == 50)
  }
}
