import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("wayRow")
struct WayRowTests {
  @Test("a way advertises the activities it suits")
  func activities() throws {
    let way = DataSchema.Way {
      $0.osm = SearchEntities.osm(type: "WAY", id: "3")
      $0.name = "GR 5"
      $0.highway = "path"
      $0.point = [6.5, 45.5]
      $0.bounds = [6, 45, 7, 46]
      $0.coordinates = [[6, 45], [7, 46]]
      $0.activityCompatible = [.hikingAndTrail]
    }
    let row = try #require(wayRow(way, query: "gr"))
    #expect(row.id == "way:WAY:3")
    #expect(row.activities == [.hikingAndTrail])
    #expect(
      row.payload
        == .way(anchor: [6.5, 45.5], bounds: [6, 45, 7, 46], coordinates: [[6, 45], [7, 46]]))
  }

  @Test("a way with no activity advertises none, and one with no point is no row")
  func edges() {
    #expect(wayRow(SearchEntities.way(), query: "")?.activities == [])
    #expect(wayRow(SearchEntities.way(point: nil), query: "") == nil)
  }

  @Test("a way's anchor drops the altitude its point carries, and its line is traced as sent")
  func altitude() throws {
    let way = DataSchema.Way {
      $0.osm = SearchEntities.osm(type: "WAY", id: "3")
      $0.name = "GR 5"
      $0.point = [6.5, 45.5, 1_200]
      $0.coordinates = [[6, 45, 1_000], [7, 46, 1_100]]
    }
    let row = try #require(wayRow(way, query: ""))
    #expect(
      row.payload
        == .way(anchor: [6.5, 45.5], bounds: nil, coordinates: [[6, 45, 1_000], [7, 46, 1_100]]))
  }
}
