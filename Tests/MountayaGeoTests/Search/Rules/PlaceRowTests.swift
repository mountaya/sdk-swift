import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("placeRow")
struct PlaceRowTests {
  @Test("a place is identified by its OpenStreetMap identity")
  func identity() throws {
    let row = try #require(placeRow(SearchEntities.place(bounds: [6, 45, 7, 46]), query: "ann"))
    #expect(row.id == "place:WAY:7")
    #expect(row.title == "Annecy")
    #expect(utf16(row.matched, in: row.title) == [0..<3])
    #expect(row.secondary == .text("Populated place"))
    #expect(row.activities.isEmpty)
    #expect(row.payload == .place(point: [6.13, 45.9], bounds: [6, 45, 7, 46]))
  }

  @Test("a place whose point names no place, or that has no identity, is no row")
  func noRow() {
    #expect(placeRow(SearchEntities.place(point: [6.13]), query: "") == nil)
    #expect(placeRow(SearchEntities.place(point: nil), query: "") == nil)
    #expect(
      placeRow(
        DataSchema.Place {
          $0.name = "Annecy"
          $0.point = [6.13, 45.9]
        }, query: "") == nil)
  }

  /// A point that states an altitude still names a place, and the payload is where a map goes, a
  /// longitude and a latitude in every SDK.
  @Test("a point with an altitude is a row whose payload drops the altitude")
  func altitude() {
    #expect(
      placeRow(SearchEntities.place(point: [6.13, 45.9, 448]), query: "")?.payload
        == .place(point: [6.13, 45.9], bounds: nil))
  }
}
