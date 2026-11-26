import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("roadAccessFeatures")
struct RoadAccessFeaturesTests {
  private let positions: [[Double]] = [[6, 45], [6.01, 45], [6.02, 45], [6.03, 45]]

  private var line: GeoJSONGeometry {
    .lineString(GeoJSONLineString(coordinates: positions))
  }

  private func stretch(from: Int, to: Int, values: String...) -> RestSchema.RoadAccessInfo {
    RestSchema.RoadAccessInfo(
      from_index: from, to_index: to,
      values: values.map { RestSchema.RoadAccessRestrictionType(rawValue: $0) })
  }

  private func piece(_ coordinates: [[Double]], kind: RoadAccessKind) -> GeoJSONFeature {
    GeoJSONFeature(
      geometry: .lineString(GeoJSONLineString(coordinates: coordinates)),
      properties: ["kind": .string(kind.id)])
  }

  @Test("each stretch is cut between its two indexes, both included, with its kind")
  func cut() {
    #expect(
      roadAccessFeatures(
        line,
        info: [
          stretch(from: 0, to: 1, values: "private"),
          stretch(from: 2, to: 3, values: "destination", "permissive"),
        ])
        == [
          piece([[6, 45], [6.01, 45]], kind: .private),
          piece([[6.02, 45], [6.03, 45]], kind: .localAccess),
        ])
    #expect(
      roadAccessFeatures(line, info: [stretch(from: 0, to: 3, values: "no")]) == [
        piece(positions, kind: .forbidden)
      ])
  }

  @Test("a stretch across two lines is cut where one ends, never across the gap")
  func twoLines() {
    let lines = GeoJSONGeometry.multiLineString(
      GeoJSONMultiLineString(coordinates: [
        [[6, 45], [6.01, 45], [6.02, 45]], [[7, 46], [7.01, 46], [7.02, 46]],
      ]))
    #expect(
      roadAccessFeatures(lines, info: [stretch(from: 1, to: 4, values: "no")]) == [
        piece([[6.01, 45], [6.02, 45]], kind: .forbidden),
        piece([[7, 46], [7.01, 46]], kind: .forbidden),
      ])
  }

  @Test("an index before the first position or past the last is clamped to the geometry")
  func clamped() {
    #expect(
      roadAccessFeatures(line, info: [stretch(from: 2, to: 9, values: "permit")]) == [
        piece([[6.02, 45], [6.03, 45]], kind: .permit)
      ])
    #expect(
      roadAccessFeatures(line, info: [stretch(from: -4, to: 99, values: "no")]) == [
        piece(positions, kind: .forbidden)
      ])
    // Indexes at the ends of an `Int`'s range are clamped as any other, with no overflow.
    #expect(
      roadAccessFeatures(line, info: [stretch(from: .min, to: .max, values: "no")]) == [
        piece(positions, kind: .forbidden)
      ])
  }

  @Test("a piece of fewer than two positions is left out")
  func short() {
    #expect(
      roadAccessFeatures(
        line,
        info: [
          stretch(from: 2, to: 2, values: "private"), stretch(from: 3, to: 9, values: "private"),
          stretch(from: 7, to: 9, values: "private"),
          stretch(from: 3, to: 1, values: "private"),
          stretch(from: .max, to: .min, values: "private"),
        ]
      ).isEmpty)
    // Positions 0 to 2 are the first line, the vias of the MultiPoint count for nothing, 3 and 4
    // are the second line and 5 to 7 the third: the piece on the third keeps one position.
    let collection = GeoJSONGeometry.geometryCollection(
      GeoJSONGeometryCollection(geometries: [
        .lineString(GeoJSONLineString(coordinates: [[6, 45], [6.01, 45], [6.02, 45]])),
        .multiPoint(GeoJSONMultiPoint(coordinates: [[6.5, 45.5]])),
        .multiLineString(
          GeoJSONMultiLineString(coordinates: [
            [[7, 46], [7.01, 46]], [[8, 47], [8.01, 47], [8.02, 47]],
          ])),
      ]))
    #expect(
      roadAccessFeatures(collection, info: [stretch(from: 1, to: 5, values: "service")]) == [
        piece([[6.01, 45], [6.02, 45]], kind: .service),
        piece([[7, 46], [7.01, 46]], kind: .service),
      ])
  }

  @Test("a stretch of no kind is left out, and a value the table does not name reads as restricted")
  func kinds() {
    #expect(
      roadAccessFeatures(
        line,
        info: [
          stretch(from: 0, to: 2, values: "permissive", "agricultural"),
          stretch(from: 0, to: 1, values: "customers"),
        ])
        == [piece([[6, 45], [6.01, 45]], kind: .localAccess)])
    #expect(roadAccessFeatures(line, info: [stretch(from: 0, to: 3, values: "permissive")]).isEmpty)
    #expect(roadAccessFeatures(line, info: [stretch(from: 0, to: 3)]).isEmpty)
    #expect(
      roadAccessFeatures(line, info: [stretch(from: 0, to: 2, values: "tolled", "forestry")]) == [
        piece([[6, 45], [6.01, 45], [6.02, 45]], kind: .restricted)
      ])
    // A value in the Data API's spelling reads as REST's.
    #expect(
      roadAccessFeatures(line, info: [stretch(from: 0, to: 1, values: "PRIVATE")]) == [
        piece([[6, 45], [6.01, 45]], kind: .private)
      ])
  }

  @Test("no stretch, and a geometry holding no line, cut nothing")
  func nothing() {
    #expect(roadAccessFeatures(line, info: nil).isEmpty)
    #expect(roadAccessFeatures(line, info: []).isEmpty)
    #expect(roadAccessFeatures(nil, info: [stretch(from: 0, to: 3, values: "no")]).isEmpty)
    #expect(
      roadAccessFeatures(
        .point(GeoJSONPoint(coordinates: [6, 45])), info: [stretch(from: 0, to: 3, values: "no")]
      )
      .isEmpty)
    #expect(
      roadAccessFeatures(
        .polygon(GeoJSONPolygon(coordinates: [[[6, 45], [6.01, 45], [6.01, 45.01], [6, 45]]])),
        info: [stretch(from: 0, to: 3, values: "no")]
      ).isEmpty)
  }

  @Test("a collection nested in another, and a line of no position, are laid end to end")
  func nested() {
    let nested = GeoJSONGeometry.geometryCollection(
      GeoJSONGeometryCollection(geometries: [
        .multiLineString(GeoJSONMultiLineString(coordinates: [[], [[6, 45], [6.01, 45]]])),
        .geometryCollection(
          GeoJSONGeometryCollection(geometries: [
            .lineString(GeoJSONLineString(coordinates: [[7, 46], [7.01, 46]]))
          ])),
      ]))
    #expect(
      roadAccessFeatures(nested, info: [stretch(from: 0, to: 3, values: "no")]) == [
        piece([[6, 45], [6.01, 45]], kind: .forbidden),
        piece([[7, 46], [7.01, 46]], kind: .forbidden),
      ])
    #expect(
      roadAccessFeatures(nested, info: [stretch(from: 1, to: 2, values: "no")]).isEmpty)
  }

  @Test("each position is kept as the geometry writes it, an altitude or a number of none")
  func asWritten() {
    let written = GeoJSONGeometry.lineString(
      GeoJSONLineString(coordinates: [[6, 45, 1200], [.nan, 45], [6.02, 45, 1250]]))
    #expect(
      roadAccessFeatures(written, info: [stretch(from: 0, to: 2, values: "no")]) == [
        piece([[6, 45, 1200], [.nan, 45], [6.02, 45, 1250]], kind: .forbidden)
      ])
  }
}
