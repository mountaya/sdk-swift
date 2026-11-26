import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("poisGeoJson")
struct PoisGeoJsonTests {
  @Test("each POI is a point carrying its figures")
  func pois() throws {
    let result = DataSchema.PoisResult {
      $0.pois = [
        DataSchema.POI {
          $0.name = "Caf\u{E9}"
          $0.category = DataSchema.POICategory(rawValue: "CAFE")
          $0.point = [6.1, 45.9]
        }
      ]
    }
    let feature = try #require(poisGeoJson(result).features.first)
    #expect(poisGeoJson(result).features.count == 1)
    #expect(feature.geometry == .point(GeoJSONPoint(coordinates: [6.1, 45.9])))
    #expect(feature.properties["elevation"] == .null)
    #expect(feature.properties["category"] == "CAFE")
    #expect(feature.properties[featureColorProperty] == .string(poiResultPointColor))
    #expect(
      Set(feature.properties.keys)
        == [
          "category", "distanceMeters", "elevation", "name", "mtyaColor", "mtyaIndex", "mtyaKind",
        ])
  }
}
