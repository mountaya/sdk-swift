import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("waypointSummary")
struct WaypointSummaryTests {
  private let words = WaypointSummaryWords(
    amenities: "Services", openingHours: { "open \($0)" }, cutoffAt: { "cut-off \($0)" },
    stop: { "stop \($0)" })
  private let english = UnitPreferences(language: "en")
  /// 2026-07-14T09:00:00Z.
  private let nine = Date(timeIntervalSince1970: 1_784_019_600)

  private func spellsNine(_ instant: Date) -> String {
    instant == nine ? "09:00" : "?"
  }

  private func timing(cutoff: Date? = nil, stop: Int? = nil) -> RestSchema.WaypointTiming {
    RestSchema.WaypointTiming {
      $0.cutoff_at = cutoff
      $0.stop_duration = stop
    }
  }

  @Test("the two clauses are joined by a middle dot")
  func joined() {
    let place = restWaypoint(
      amenities: ["water", "medical-post"], timing: timing(cutoff: nine, stop: 900))
    #expect(waypointSummary(place, words: words, units: english) == "Services · stop 15m")
    #expect(
      waypointSummary(place, words: words, units: english, formatCutoffAt: spellsNine)
        == "Services · cut-off 09:00")
  }

  @Test("the opening hours win, then the cut-off the caller can spell, then the stop")
  func order() {
    let contact = RestSchema.WaypointContact { $0.opening_hours = "8:00 to 18:00" }
    #expect(
      waypointSummary(
        restWaypoint(timing: timing(cutoff: nine, stop: 900), contact: contact), words: words,
        units: english, formatCutoffAt: spellsNine) == "open 8:00 to 18:00")
    #expect(
      waypointSummary(
        restWaypoint(timing: timing(cutoff: nine)), words: words, units: english,
        formatCutoffAt: spellsNine) == "cut-off 09:00")
    #expect(
      waypointSummary(restWaypoint(timing: timing(stop: 900)), words: words, units: english)
        == "stop 15m")
    let emptyHours = RestSchema.WaypointContact { $0.opening_hours = "" }
    #expect(
      waypointSummary(
        restWaypoint(timing: timing(stop: 900), contact: emptyHours), words: words, units: english)
        == "stop 15m")
  }

  @Test("a place with nothing to say has no summary")
  func nothing() {
    #expect(waypointSummary(restWaypoint(), words: words, units: english) == nil)
    #expect(
      waypointSummary(restWaypoint(timing: timing(cutoff: nine)), words: words, units: english)
        == nil)
    #expect(
      waypointSummary(restWaypoint(timing: timing(stop: 20)), words: words, units: english) == nil)
    let phone = RestSchema.WaypointContact { $0.phone = "+33450123456" }
    #expect(waypointSummary(restWaypoint(contact: phone), words: words, units: english) == nil)
  }

  @Test("the stop is stated in the reader's language")
  func language() {
    #expect(
      waypointSummary(
        restWaypoint(timing: timing(stop: 5_400)), words: words,
        units: UnitPreferences(language: "fr"))
        == "stop 1h 30min")
  }
}
