import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itineraryRow")
struct ItineraryRowTests {
  @Test("an itinerary states its figures for the surface to word")
  func figures() throws {
    let row = try #require(
      itineraryRow(
        DataSchema.ItinerarySearchResult {
          $0.id = "it-1"
          $0.name = "Haute Route"
          $0.distance = 24_500
          $0.ascent = 1_450
          $0.activitySlug = .skiTouring
          $0.start = [6.1, 45.1]
        }, query: "haute"))
    #expect(row.id == "itinerary:it-1")
    #expect(utf16(row.matched, in: row.title) == [0..<5])
    #expect(row.secondary == .metric(distance: 24_500, ascent: 1_450))
    #expect(row.activities == [.skiTouring])
    #expect(row.payload == .itinerary(itineraryId: "it-1", bounds: nil, start: [6.1, 45.1]))
  }

  @Test("an itinerary with no figures states none, and one with no id is no row")
  func edges() {
    let bare = itineraryRow(DataSchema.ItinerarySearchResult { $0.id = "it-2" }, query: "")
    #expect(bare?.secondary == .metric(distance: nil, ascent: nil))
    #expect(bare?.title == "")
    #expect(bare?.activities == [])
    #expect(itineraryRow(DataSchema.ItinerarySearchResult { $0.name = "No id" }, query: "") == nil)
  }

  @Test("an itinerary's start drops the altitude its point carries")
  func altitude() {
    let row = itineraryRow(
      DataSchema.ItinerarySearchResult {
        $0.id = "it-1"
        $0.start = [6.1, 45.1, 1_035]
      }, query: "")
    #expect(row?.payload == .itinerary(itineraryId: "it-1", bounds: nil, start: [6.1, 45.1]))
  }
}
