import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("readItineraryDirectionsSteps")
struct ReadItineraryDirectionsStepsTests {
  private func step(_ type: String, from: Int, to: Int, name: String, exit: Int? = nil)
    -> RestSchema.ItineraryDirectionsStep
  {
    RestSchema.ItineraryDirectionsStep(
      distance: 8_400, duration: 7_200, exit_number: exit, from_index: from, name: name,
      to_index: to, type: RestSchema.ManeuverType(rawValue: type))
  }

  @Test("a REST step is read as written")
  func asWritten() {
    let reading = readItineraryDirectionsSteps(
      [
        step("depart", from: 0, to: 1, name: "Route des Chavants"),
        step("goal", from: 1, to: 2, name: "-"),
      ], coordinateCount: 3)

    #expect(
      reading
        == NavigationStepsReading(
          refused: false,
          steps: [
            NavigationStep(
              fromIndex: 0, toIndex: 1, maneuver: .depart, name: "Route des Chavants",
              distance: 8_400, duration: 7_200),
            NavigationStep(
              fromIndex: 1, toIndex: 2, maneuver: .goal, distance: 8_400,
              duration: 7_200),
          ]))
  }

  /// A member REST adds after this build, and the Data API's spelling, are said as `unknown`, and
  /// the step is kept with everything else it states.
  @Test("a maneuver REST does not spell is unknown, and the step is kept")
  func unknownKept() {
    let reading = readItineraryDirectionsSteps(
      [
        step("merge", from: 0, to: 1, name: "Route Blanche", exit: 2),
        step("TURN_LEFT", from: 1, to: 2, name: ""),
      ],
      coordinateCount: 3)

    #expect(reading.steps.map(\.maneuver) == [.unknown, .unknown])
    #expect(reading.steps[0].exitNumber == 2)
    #expect(reading.steps[0].name == "Route Blanche")
  }

  @Test("a segment with no steps is no refusal, and one that does not tile is refused")
  func noStepsAndRefusal() {
    #expect(
      readItineraryDirectionsSteps(nil, coordinateCount: 3)
        == NavigationStepsReading(refused: false, steps: []))
    #expect(
      readItineraryDirectionsSteps([step("depart", from: 0, to: 1, name: "")], coordinateCount: 3)
        == NavigationStepsReading(refused: true, steps: []))
  }
}
