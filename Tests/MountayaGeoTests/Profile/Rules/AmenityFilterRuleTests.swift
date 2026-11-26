import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("amenityFilter")
struct AmenityFilterRuleTests {
  private func rows(_ places: [[RestSchema.WaypointAmenity]]) -> [ItineraryWaypointRow] {
    places.enumerated().map { index, services in
      ItineraryWaypointRow(
        key: "row#\(index)",
        place: ProfilePlace(
          .atDistance(id: "row", distance: Double(index)),
          details: services.isEmpty ? nil : WaypointDetails(amenities: services)),
        index: index, from: 0, to: Double(index),
        metrics: ItineraryWaypointRowMetrics(distance: Double(index)))
    }
  }

  private var table: [ItineraryWaypointRow] {
    rows([["water", "food"], ["water"], ["toilets", "water", "food"]])
  }

  @Test("a row stays only where it offers every service picked, every row with none picked")
  func shown() {
    #expect(
      amenityFilter(table, picked: ["water", "food"], scope: .standard).shown.map(\.index) == [
        0, 2,
      ])
    #expect(amenityFilter(table, picked: [], scope: .standard).shown.map(\.index) == [0, 1, 2])
    #expect(amenityFilter(table, picked: ["showers"], scope: .standard).shown.isEmpty)
  }

  @Test(
    "the chips sort by the reader's name in the reader's language, a service with none by its value"
  )
  func chips() {
    #expect(
      amenityFilter(table, picked: [], scope: .standard).available == [
        "food", "toilets", "water",
      ])
    let french = scopeOf(.standard, stating: ElementsScopeStatement(language: .fr))
    #expect(
      amenityFilter(table, picked: [], scope: french).available == ["water", "food", "toilets"])
    #expect(
      amenityFilter(rows([["water"], ["sauna", "food"], []]), picked: [], scope: .standard)
        .available
        == ["food", "sauna", "water"])
  }
}
