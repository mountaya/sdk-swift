import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itineraryRoute")
struct ItineraryRouteTests {
  /// segment is a segment as the API answers one, holding a geometry at a position in the chain,
  /// and a placeholder for every member the rule never reads.
  private func segment(_ id: String, at position: Int, geometry: GeoJSONGeometry?)
    -> RestSchema.ItinerarySegment
  {
    RestSchema.ItinerarySegment(
      altitude_max: nil, altitude_min: nil, ascent: nil, color: nil,
      created_at: Date(timeIntervalSince1970: 0), created_by: RestSchema.RelationToUser(id: "user"),
      descent: nil, description: nil, distance: nil, duration: nil, geojson: geometry,
      gradient_max: nil, gradient_min: nil, group_id: nil, id: id, itinerary_id: "itinerary",
      mode: .linestring, name: id, position: position, revision: 1,
      road_access_info: nil, slope_info: nil, speed: nil, speed_info: nil, start_at: nil,
      steps: nil, surface_info: nil, trail_difficulty_info: nil, way_type_info: nil)
  }

  private func line(_ positions: [Double]...) -> GeoJSONGeometry {
    .lineString(GeoJSONLineString(coordinates: positions))
  }

  @Test("a line is the route")
  func aLine() {
    #expect(
      itineraryRoute([segment("a", at: 0, geometry: line([6, 45], [6.5, 45.5], [7, 46]))])
        == RouteGeometry(line: [[6, 45], [6.5, 45.5], [7, 46]]))
  }

  @Test("the elevations are stated only where every vertex carries a finite one")
  func elevations() {
    let climbing = line([6, 45, 1_200], [6.5, 45.5, 1_350], [7, 46, 1_500])
    let gapped = line([6, 45, 1_200], [6.5, 45.5], [7, 46, 1_500])
    let unmeasured = line([6, 45, 1_200], [6.5, 45.5, .nan])
    let flat: [[Double]] = [[6, 45], [6.5, 45.5], [7, 46]]
    #expect(
      itineraryRoute([segment("a", at: 0, geometry: climbing)])
        == RouteGeometry(line: flat, elevations: [1_200, 1_350, 1_500]))
    #expect(itineraryRoute([segment("a", at: 0, geometry: gapped)]) == RouteGeometry(line: flat))
    #expect(
      itineraryRoute([segment("a", at: 0, geometry: unmeasured)])
        == RouteGeometry(line: Array(flat.prefix(2))))
  }

  /// The vertex each line after the first starts on is a jump, the duplicate vertex included.
  @Test("the segments are laid end to end in chain order, naming each jump")
  func chainOrder() {
    let first = segment("a", at: 0, geometry: line([6, 45], [6.5, 45.5]))
    let second = segment("b", at: 1, geometry: line([6.5, 45.5], [7, 46]))
    let expected = RouteGeometry(
      line: [[6, 45], [6.5, 45.5], [6.5, 45.5], [7, 46]], jumps: [2])
    #expect(itineraryRoute([first, second]) == expected)
    #expect(itineraryRoute([second, first]) == expected)
  }

  @Test("two segments at one position keep the order they are listed in")
  func stable() {
    let first = segment("a", at: 0, geometry: line([6, 45], [6.5, 45.5]))
    let second = segment("b", at: 0, geometry: line([7, 46], [7.5, 46.5]))
    #expect(itineraryRoute([first, second])?.line.first == [6, 45])
    #expect(itineraryRoute([second, first])?.line.first == [7, 46])
  }

  @Test("every line a segment holds is flown, and its vias are not")
  func everyLine() {
    let collection = GeoJSONGeometry.geometryCollection(
      GeoJSONGeometryCollection(geometries: [
        .multiLineString(
          GeoJSONMultiLineString(coordinates: [
            [[6, 45], [6.01, 45]], [[6.02, 45], [6.03, 45]],
          ])),
        line([6.04, 45], [6.05, 45]),
        .multiPoint(GeoJSONMultiPoint(coordinates: [[7, 46]])),
        .point(GeoJSONPoint(coordinates: [8, 47])),
      ]))
    #expect(
      itineraryRoute([segment("a", at: 0, geometry: collection)])
        == RouteGeometry(
          line: [[6, 45], [6.01, 45], [6.02, 45], [6.03, 45], [6.04, 45], [6.05, 45]],
          jumps: [2, 4]
        ))
  }

  @Test("one segment is flown by its id, and an unknown id is no route")
  func byId() {
    let first = segment("a", at: 0, geometry: line([6, 45], [6.5, 45.5]))
    let second = segment("b", at: 1, geometry: line([7, 46], [7.5, 46.5]))
    #expect(
      itineraryRoute([first, second], segmentId: "b")
        == RouteGeometry(line: [[7, 46], [7.5, 46.5]]))
    #expect(itineraryRoute([first, second], segmentId: "missing") == nil)
  }

  /// A vertex that names no place is left out with its elevation, and the others keep theirs.
  @Test("a vertex that names no place is left out, and a line of none opens no line")
  func leftOut() {
    let holed = line([6, 45, 1_000], [.nan, 45, 1_100], [6.5], [7, 46, 1_200])
    #expect(
      itineraryRoute([segment("a", at: 0, geometry: holed)])
        == RouteGeometry(line: [[6, 45], [7, 46]], elevations: [1_000, 1_200]))
    // A line whose every vertex names no place opens no line, so it names no jump.
    let empty = segment("b", at: 1, geometry: line([.nan, 45]))
    let after = segment("c", at: 2, geometry: line([8, 47], [8.5, 47.5]))
    #expect(itineraryRoute([segment("a", at: 0, geometry: holed), empty, after])?.jumps == [2])
  }

  @Test("fewer than two places is no route, and two lines of one vertex are one jumped leg")
  func fewerThanTwo() {
    #expect(itineraryRoute([]) == nil)
    #expect(itineraryRoute([segment("a", at: 0, geometry: line([6, 45]))]) == nil)
    #expect(itineraryRoute([segment("a", at: 0, geometry: nil)]) == nil)
    #expect(
      itineraryRoute([
        segment(
          "a", at: 0, geometry: .multiPoint(GeoJSONMultiPoint(coordinates: [[6, 45], [7, 46]])))
      ])
        == nil)
    #expect(
      itineraryRoute([
        segment("a", at: 0, geometry: line([6, 45])), segment("b", at: 1, geometry: line([7, 46])),
      ])
        == RouteGeometry(line: [[6, 45], [7, 46]], jumps: [1]))
  }
}
