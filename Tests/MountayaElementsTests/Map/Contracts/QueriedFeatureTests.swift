import MountayaClient
import MountayaElements
import MountayaGeo
import Testing

@Suite("QueriedFeature")
struct QueriedFeatureTests {
  private static let point = GeoJSONGeometry.point(GeoJSONPoint(coordinates: [6.9, 45.9]))

  @Test("a property holding a list or an object is left out, every other kept, null included")
  func properties() {
    let feature = QueriedFeature(
      id: .string("poi-12"),
      properties: [
        "cuisine": ["savoyard", "pizza"], "hours": ["open": "08:00"], "name": "Buvette",
        "open": true, "seats": 24, "website": .null,
      ], geometry: Self.point, layer: "poi-food", sourceLayer: "poi_food")
    #expect(feature.properties.keys.sorted() == ["name", "open", "seats", "website"])
    #expect(feature.properties["website"] == .null)
    #expect(feature.id == .string("poi-12"))
    #expect(feature.layer == "poi-food" && feature.sourceLayer == "poi_food")
  }

  @Test("two features are equal where every member is the same, by scalars and same numbers")
  func equality() {
    let a = QueriedFeature(id: .number(7), properties: [:], geometry: Self.point, layer: "line")
    #expect(
      a == QueriedFeature(id: .number(7), properties: [:], geometry: Self.point, layer: "line"))
    #expect(
      a != QueriedFeature(id: .string("7"), properties: [:], geometry: Self.point, layer: "line"))
    #expect(
      a != QueriedFeature(id: .number(7), properties: [:], geometry: Self.point, layer: "casing"))
    #expect(
      a
        != QueriedFeature(
          id: .number(7), properties: [:], geometry: Self.point, layer: "line", sourceLayer: "lines"
        ))
    #expect(QueriedFeature.ID.number(.nan) == .number(.nan))
    #expect(QueriedFeature.ID.string("caf\u{E9}") != .string("cafe\u{301}"))
  }
}
