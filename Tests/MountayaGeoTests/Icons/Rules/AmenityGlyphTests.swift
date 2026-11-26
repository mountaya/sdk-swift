import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("amenityGlyph")
struct AmenityGlyphTests {
  @Test("an amenity's glyph is its name under the namespace")
  func glyph() {
    #expect(amenityGlyph(.water) == "amenity-water")
    #expect(
      amenityGlyph(RestSchema.WaypointAmenity(rawValue: "medical-post")) == "amenity-medical-post")
  }

  @Test("the amenities are the thirty the contract names, once each")
  func amenities() {
    #expect(waypointAmenities.count == 30)
    #expect(Set(waypointAmenities).count == 30)
    #expect(waypointAmenities.first?.rawValue == "water")
    #expect(waypointAmenities.last?.rawValue == "timing-checkpoint")
  }
}
