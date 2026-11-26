import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("readDirectionsSteps")
struct ReadDirectionsStepsTests {
  private func step(
    _ maneuver: DataSchema.ManeuverType?, from: Int?, to: Int?, name: String? = nil,
    exit: Int? = nil
  ) -> DataSchema.DirectionsStep {
    DataSchema.DirectionsStep {
      $0.fromIndex = from
      $0.toIndex = to
      $0.type = maneuver
      $0.name = name
      $0.distance = 180
      $0.duration = 150
      $0.exitNumber = exit
    }
  }

  @Test("a Data API step is read into REST's vocabulary")
  func intoRest() {
    let reading = readDirectionsSteps(
      [
        step(.depart, from: 0, to: 1, name: "Rue du Docteur Paccard"),
        step(.enterRoundabout, from: 1, to: 3, name: "-", exit: 2),
        step(.goal, from: 3, to: 3, name: ""),
      ],
      coordinateCount: 4)

    #expect(
      reading
        == NavigationStepsReading(
          refused: false,
          steps: [
            NavigationStep(
              fromIndex: 0, toIndex: 1, maneuver: .depart,
              name: "Rue du Docteur Paccard", distance: 180, duration: 150),
            NavigationStep(
              fromIndex: 1, toIndex: 3, maneuver: .enterRoundabout, distance: 180,
              duration: 150, exitNumber: 2),
            NavigationStep(
              fromIndex: 3, toIndex: 3, maneuver: .goal, distance: 180, duration: 150),
          ]))
  }

  /// The Data API's members are nullable by selection: a figure it states none of is none, and a
  /// maneuver it states none of is said as one outside the set.
  @Test("a member the step does not state is none")
  func unstated() {
    let reading = readDirectionsSteps(
      [
        DataSchema.DirectionsStep {
          $0.fromIndex = 0
          $0.toIndex = 1
        }
      ],
      coordinateCount: 2)

    #expect(
      reading.steps == [NavigationStep(fromIndex: 0, toIndex: 1, maneuver: .unknown)])
  }

  /// A step that states no range indexes no vertex, so the list does not tile.
  @Test("a step that states no range refuses the list")
  func noRange() {
    #expect(
      readDirectionsSteps([step(nil, from: 0, to: nil)], coordinateCount: 2)
        == NavigationStepsReading(refused: true, steps: []))
    #expect(
      readDirectionsSteps([step(nil, from: nil, to: 1)], coordinateCount: 2)
        == NavigationStepsReading(refused: true, steps: []))
  }

  @Test("a list that does not tile is refused whole")
  func refusedWhole() {
    let reading = readDirectionsSteps(
      [step(.depart, from: 1, to: 2), step(.goal, from: 2, to: 3)], coordinateCount: 4)

    #expect(reading == NavigationStepsReading(refused: true, steps: []))
  }

  @Test("no list and an empty one are no steps and no refusal")
  func noList() {
    #expect(
      readDirectionsSteps(nil, coordinateCount: 3)
        == NavigationStepsReading(refused: false, steps: []))
    #expect(
      readDirectionsSteps([], coordinateCount: 3)
        == NavigationStepsReading(refused: false, steps: []))
  }
}
