import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("zoneRow")
struct ZoneRowTests {
  @Test("a zone states its own description")
  func description() throws {
    let row = try #require(
      zoneRow(
        DataSchema.ZoneSearchResult {
          $0.id = "zone-1"
          $0.name = "Couloir closure"
          $0.description = "Wind slab above the couloir"
          $0.point = [6.5, 45.5]
        }, query: "couloir"))
    #expect(row.id == "zone:zone-1")
    #expect(row.secondary == .text("Wind slab above the couloir"))
    #expect(row.payload == .zone(zoneId: "zone-1", point: [6.5, 45.5], bounds: nil))
  }

  @Test("a zone with no description is its title alone")
  func noDescription() {
    #expect(zoneRow(DataSchema.ZoneSearchResult { $0.id = "z" }, query: "")?.secondary == nil)
    #expect(zoneRow(DataSchema.ZoneSearchResult { $0.name = "z" }, query: "") == nil)
  }

  @Test("a zone's anchor drops the altitude its point carries")
  func altitude() {
    let row = zoneRow(
      DataSchema.ZoneSearchResult {
        $0.id = "zone-1"
        $0.point = [6.5, 45.5, 2_000]
      }, query: "")
    #expect(row?.payload == .zone(zoneId: "zone-1", point: [6.5, 45.5], bounds: nil))
  }
}
