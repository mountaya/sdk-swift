import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("poiRow")
struct PoiRowTests {
  @Test("a POI carries its category to the payload")
  func category() throws {
    let row = try #require(poiRow(SearchEntities.poi(distance: 850), query: "gouter"))
    #expect(row.id == "poi:NODE:9")
    #expect(utf16(row.matched, in: row.title) == [10..<16])
    #expect(row.secondary == .text("Hut \u{B7} 850 m"))
    #expect(row.payload == .poi(point: [6.5, 45.8], category: .hut))
  }

  @Test("a POI with no name is titled by its category, and states it once")
  func noName() throws {
    let row = try #require(poiRow(SearchEntities.poi(name: "", category: "CAFE"), query: ""))
    #expect(row.title == "Cafe")
    #expect(row.secondary == nil)
    #expect(row.matched.isEmpty)
  }

  @Test("a POI whose point names no place is no row, and one with an altitude drops it")
  func noPlace() {
    #expect(poiRow(SearchEntities.poi(point: []), query: "") == nil)
    #expect(
      poiRow(SearchEntities.poi(point: [6.5, 45.8, 3_817]), query: "")?.payload
        == .poi(point: [6.5, 45.8], category: .hut))
  }
}
