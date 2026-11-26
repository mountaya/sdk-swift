import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("chainGeometry")
struct ChainGeometryTests {
  @Test("a chain is the collection of its legs' geometries in its order, a leg with none left out")
  func chain() {
    let first: GeoJSONGeometry = .lineString(
      GeoJSONLineString(coordinates: [[6, 45], [6, 45.005]]))
    let second: GeoJSONGeometry = .lineString(
      GeoJSONLineString(coordinates: [[6, 45.005], [6, 45.01]]))
    let geometry = chainGeometry([
      ItineraryLeg(id: "s1", name: "a", geometry: first), ItineraryLeg(id: "t", name: "transfer"),
      ItineraryLeg(id: "s2", name: "b", geometry: second),
    ])
    #expect(
      geometry == .geometryCollection(GeoJSONGeometryCollection(geometries: [first, second])))
    #expect(chainGeometry([ItineraryLeg(id: "t", name: "transfer")]) == nil)
    #expect(chainGeometry([]) == nil)
  }
}
