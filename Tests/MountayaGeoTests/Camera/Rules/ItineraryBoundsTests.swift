import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itineraryBounds")
struct ItineraryBoundsTests {
  private static func segment(_ position: Int, geometry geojson: GeoJSONGeometry?)
    -> RestSchema.ItinerarySegment
  {
    RestSchema.ItinerarySegment(
      altitude_max: nil, altitude_min: nil, ascent: nil, color: nil,
      created_at: Date(timeIntervalSince1970: 0), created_by: RestSchema.RelationToUser(id: "user"),
      descent: nil, description: nil, distance: nil, duration: nil, geojson: geojson,
      gradient_max: nil, gradient_min: nil, group_id: nil, id: "s\(position)",
      itinerary_id: "itinerary", mode: .linestring, name: "s\(position)",
      position: position, revision: 1, road_access_info: nil, slope_info: nil, speed: nil,
      speed_info: nil, start_at: nil, steps: nil, surface_info: nil, trail_difficulty_info: nil,
      way_type_info: nil)
  }

  private static func collection(_ geometries: GeoJSONGeometry...) -> GeoJSONGeometry {
    .geometryCollection(GeoJSONGeometryCollection(geometries: geometries))
  }

  private static func line(_ positions: [Double]...) -> GeoJSONGeometry {
    .lineString(GeoJSONLineString(coordinates: positions))
  }

  @Test("the box spans every segment's stored geometry, a directions segment's vias included")
  func segments() {
    #expect(
      itineraryBounds([
        Self.segment(0, geometry: Self.collection(Self.line([6.86, 45.83], [6.92, 45.88])))
      ])
        == [6.86, 45.83, 6.92, 45.88])
    let vias = Self.collection(
      Self.line([6.86, 45.83], [6.92, 45.88]),
      .multiPoint(GeoJSONMultiPoint(coordinates: [[6.95, 45.79]])))
    #expect(itineraryBounds([Self.segment(0, geometry: vias)]) == [6.86, 45.79, 6.95, 45.88])
    // Every segment counts, whatever its place in the chain.
    #expect(
      itineraryBounds([
        Self.segment(1, geometry: Self.collection(Self.line([7.02, 45.9], [7.1, 45.95]))),
        Self.segment(0, geometry: Self.collection(Self.line([6.86, 45.83], [6.92, 45.88]))),
      ]) == [6.86, 45.83, 7.1, 45.95])
  }

  @Test("a segment with no geometry adds nothing, and none at all frames nothing")
  func noGeometry() {
    #expect(
      itineraryBounds([
        Self.segment(0, geometry: nil),
        Self.segment(1, geometry: Self.collection(Self.line([6.86, 45.83], [6.92, 45.88]))),
      ]) == [6.86, 45.83, 6.92, 45.88])
    #expect(
      itineraryBounds([Self.segment(0, geometry: nil), Self.segment(1, geometry: nil)]) == nil)
    #expect(itineraryBounds([]) == nil)
  }

  @Test("a chain straddling the antimeridian is framed across it, its east edge past 180")
  func antimeridian() {
    #expect(
      itineraryBounds([
        Self.segment(0, geometry: Self.collection(Self.line([179.5, -16], [179.9, -16.5]))),
        Self.segment(1, geometry: Self.collection(Self.line([-179.9, -16.7], [-179.5, -17]))),
      ]) == [179.5, -17, 180.5, -16])
  }
}
