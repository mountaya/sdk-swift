import MountayaClient
import Testing

@testable import MountayaElements

@Suite("LegEmphasisTarget")
@MainActor
struct LegEmphasisTargetTests {
  @Test("a map is a target its emphasis slot is written and cleared through")
  func engine() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .publishable(key: "pk_test_a")),
      geolocation: InertGeolocation())
    let target: any LegEmphasisTarget = map
    let line: GeoJSONGeometry = .lineString(GeoJSONLineString(coordinates: [[6, 45], [6, 45.1]]))
    target.setGeometry(line, in: .emphasis, color: "#e8590c")
    #expect(map.geometry(in: .emphasis) == SlotGeometry(geometry: line, color: "#e8590c"))
    target.clearGeometry(in: .emphasis)
    #expect(
      map.geometry(in: .emphasis) == SlotGeometry(geometry: nil, color: GeometrySlot.emphasis.color)
    )
  }
}
