import Foundation
import MountayaClient
import MountayaGeo
import XCTest

/// The journey of the contract's `sdk/trail.yaml`, walked through Trail as a person walks it: no
/// setting is set, so the app shows its notice and holds the demo itinerary, and Replay walks the
/// route at the journey's speed. Each check is the journey's, in its order, by the accessibility
/// identifier it acts on.
///
/// The test reads what the voice may say off the demo itinerary itself, the app's copy, through
/// the same words the app says them with, `Words.swift`, which this target compiles beside it.
final class TrailUITests: XCTestCase {
  /// replayMetersPerSecond is `journey.replayMetersPerSecond`, the replay speed only a test hands
  /// the app.
  static let replayMetersPerSecond = 100.0

  /// arrivalSeconds is `journey.arrivalSeconds`, the longest the arrival may take after Start.
  static let arrivalSeconds = 30.0

  /// waypoints is `journey.waypoints`, the waypoint instructions the demo's route yields, in
  /// travel order.
  static let waypoints = ["Les Nants", "Clairière des Nants"]

  @MainActor
  func testTheJourneyFollowsTheDemoItineraryPastItsWaypointsToItsEnd() throws {
    // Every sentence the voice may say on the demo's route, and those that pass a waypoint.
    let demo = try XCTUnwrap(
      Bundle(for: Self.self).url(forResource: "itinerary", withExtension: "json"))
    let itinerary = try JSONDecoder().decode(
      RestSchema.ItineraryWithDetails.self, from: Data(contentsOf: demo))
    let route = try XCTUnwrap(
      readItineraryRoute(itinerary.segments, waypoints: itinerary.waypoints))
    let instructions = route.steps.map(stepInstruction)
    let said = Set(instructions.map(sentence(for:)))
    let passed = instructions.filter { $0.key == .waypoint }
    XCTAssertEqual(passed.compactMap(\.name), Self.waypoints)
    let passing = Set(passed.map(sentence(for:)))

    // No setting: each read as none, whatever Config/Local.xcconfig holds, the replay at the
    // journey's speed, and the device's language pinned so the profile's words are known.
    let app = XCUIApplication()
    app.launchEnvironment = [
      "MOUNTAYA_PUBLISHABLE_KEY": "", "MOUNTAYA_ITINERARY_ID": "", "MOUNTAYA_SESSION_URL": "",
      "TRAIL_REPLAY_METERS_PER_SECOND": String(Self.replayMetersPerSecond),
    ]
    app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()

    // trail.notice, see: the notice stands in place of the map and the search, since no
    // publishable key is set.
    let notice = app.staticTexts["trail.notice"]
    XCTAssertTrue(notice.waitForExistence(timeout: 30), "no notice")

    // trail.profile, see: the profile draws the demo itinerary's elevation, since no itinerary id
    // is set: its chart stands once the elevation is drawn.
    let profile = app.descendants(matching: .any).matching(identifier: "trail.profile").firstMatch
    XCTAssertTrue(profile.waitForExistence(timeout: 30), "no profile")
    let chart = profile.descendants(matching: .any)
      .matching(identifier: ElementsScope.standard.word("profile.chart")).firstMatch
    XCTAssertTrue(chart.waitForExistence(timeout: 30), "the profile drew no elevation")

    // trail.replay, press: Replay is switched on, so the route is walked at the journey's speed.
    let replay = app.switches["trail.replay"]
    XCTAssertTrue(replay.waitForExistence(timeout: 10), "no Replay")
    replay.tap()
    XCTAssertEqual(replay.value as? String, "1", "Replay is not on")

    // trail.start, press: Start begins following the demo itinerary, its segments joined into
    // one route.
    let start = app.buttons["trail.start"]
    XCTAssertTrue(start.waitForExistence(timeout: 10), "no Start")
    start.tap()
    let pressed = Date()

    // trail.instruction, read: an instruction is shown, in the wording the voice says it with.
    var shown: [String] = []
    while Date().timeIntervalSince(pressed) < Self.arrivalSeconds {
      let marked = try Self.marked(in: app)
      if let instruction = marked["trail.instruction"] {
        shown.append(instruction)
        break
      }
    }
    let first = try XCTUnwrap(shown.first, "no instruction was shown")
    XCTAssertTrue(said.contains(first), "`\(first)` is no sentence the voice says: \(said)")

    // trail.instruction, read: a waypoint's instruction is shown at least once, said with the
    // `waypoint` key and naming one of the journey's waypoints; trail.arrived, see: the arrival,
    // within the journey's time of the press on Start.
    var arrivedAfter: TimeInterval?
    while arrivedAfter == nil, Date().timeIntervalSince(pressed) < Self.arrivalSeconds + 5 {
      let marked = try Self.marked(in: app)
      if let instruction = marked["trail.instruction"], shown.last != instruction {
        shown.append(instruction)
      }
      if marked["trail.arrived"] != nil {
        arrivedAfter = Date().timeIntervalSince(pressed)
      }
    }
    let named = shown.filter { words in
      passing.contains(words) && Self.waypoints.contains { words.contains($0) }
    }
    XCTAssertFalse(named.isEmpty, "no instruction passed a waypoint by its name: \(shown)")
    XCTAssertTrue(said.isSuperset(of: shown), "\(shown) is not all the voice says: \(said)")
    let took = try XCTUnwrap(arrivedAfter, "no arrival within \(Self.arrivalSeconds) s: \(shown)")
    XCTAssertLessThanOrEqual(took, Self.arrivalSeconds, "the arrival took \(took) s")
    print("journey: shown \(shown), arrived \(took) s after Start")

    // trail.stop, press: Stop ends the navigation, and Start is shown again.
    app.buttons["trail.stop"].tap()
    XCTAssertTrue(start.waitForExistence(timeout: 10), "Start is not shown again")
    XCTAssertFalse(app.buttons["trail.stop"].exists)
    XCTAssertFalse(app.staticTexts["trail.arrived"].exists)
  }

  @MainActor
  func testTheSheetNeverRisesIntoTheWatermarksFrame() throws {
    // No setting, so the notice stands 8 points under the top of the screen's visible part.
    let app = XCUIApplication()
    app.launchEnvironment = [
      "MOUNTAYA_PUBLISHABLE_KEY": "", "MOUNTAYA_ITINERARY_ID": "", "MOUNTAYA_SESSION_URL": "",
    ]
    app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    let notice = app.staticTexts["trail.notice"]
    XCTAssertTrue(notice.waitForExistence(timeout: 30), "no notice")

    // The sheet opened onto its tables, as tall as it grows.
    let handle = app.buttons[Words.details]
    XCTAssertTrue(handle.waitForExistence(timeout: 10), "no handle")
    handle.tap()
    let sheet = app.otherElements["trail.sheet"]
    XCTAssertTrue(sheet.waitForExistence(timeout: 10), "no sheet")
    let visibleTop = notice.frame.minY - 8
    XCTAssertGreaterThanOrEqual(
      sheet.frame.minY, visibleTop + CGFloat(watermarkClearance) - 0.5,
      "the sheet rose into the frame the watermark stands in")
  }

  /// marked is the label of every element of `app` that carries an accessibility identifier, by
  /// its identifier, read in one snapshot so an element that goes as it is read fails nothing.
  @MainActor
  static func marked(in app: XCUIApplication) throws -> [String: String] {
    var found: [String: String] = [:]
    var pending = [try app.snapshot()]
    while let element = pending.popLast() {
      if !element.identifier.isEmpty {
        found[element.identifier] = element.label
      }
      pending += element.children
    }
    return found
  }
}
