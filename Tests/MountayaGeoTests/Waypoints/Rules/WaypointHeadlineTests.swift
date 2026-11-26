import Testing

@testable import MountayaGeo

@Suite("waypointHeadline")
struct WaypointHeadlineTests {
  private let words = WaypointSummaryWords(
    amenities: "Services", openingHours: { "open \($0)" }, cutoffAt: { "cut-off \($0)" },
    stop: { "stop \($0)" })
  private let english = UnitPreferences(language: "en")

  @Test("a description wins the headline, and the summary stands in for none")
  func headline() {
    #expect(
      waypointHeadline(
        restWaypoint(amenities: ["hut"], description: " The old refuge.\n"), words: words,
        units: english) == "The old refuge.")
    #expect(
      waypointHeadline(
        restWaypoint(amenities: ["hut"], description: "  "), words: words, units: english)
        == "Services")
    #expect(
      waypointHeadline(restWaypoint(amenities: ["hut"]), words: words, units: english) == "Services"
    )
    #expect(waypointHeadline(restWaypoint(), words: words, units: english) == nil)
  }
}
