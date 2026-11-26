import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("placesGeoJson")
struct PlacesGeoJsonTests {
  @Test("each place is a point, labelled")
  func places() throws {
    let result = DataSchema.GeocodeResult {
      $0.places = [
        DataSchema.Place {
          $0.name = "Annecy"
          $0.category = .populatedPlace
          $0.point = [6.13, 45.9]
        },
        DataSchema.Place {
          $0.name = "Nowhere"
          $0.point = [6.13]
        },
      ]
    }
    let features = placesGeoJson(result).features
    try #require(features.count == 2)
    #expect(features[0].geometry == .point(GeoJSONPoint(coordinates: [6.13, 45.9])))
    #expect(features[0].properties["category"] == "POPULATED_PLACE")
    #expect(features[0].properties["bounds"] == .null)
    #expect(features[0].properties[featureColorProperty] == .string(placePointColor))
    #expect(features[0].properties[featureKindProperty] == "place")
    // A place whose point names no place is drawn nowhere, its index kept.
    #expect(features[1].geometry == nil)
    #expect(features[1].properties[featureIndexProperty] == 1)
  }
}
