import Testing

@testable import MountayaGeo

@Suite("WaypointSummaryWords")
struct WaypointSummaryWordsTests {
  /// Swift compares no two functions, so two copies are never compared: no rule needs to.
  @Test("the clauses are the caller's words")
  func clauses() {
    let words = WaypointSummaryWords(
      amenities: "Services", openingHours: { "open \($0)" }, cutoffAt: { "cut-off \($0)" },
      stop: { "stop \($0)" })
    #expect(words.amenities == "Services")
    #expect(words.openingHours("8:00 to 18:00") == "open 8:00 to 18:00")
    #expect(words.cutoffAt("09:00") == "cut-off 09:00")
    #expect(words.stop("15m") == "stop 15m")
  }
}
