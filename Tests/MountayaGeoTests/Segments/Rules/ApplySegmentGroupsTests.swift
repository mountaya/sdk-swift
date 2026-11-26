import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("applySegmentGroups")
struct ApplySegmentGroupsTests {
  private let group = RestSchema.ItinerarySegmentGroup(
    color: "#e9501e", created_at: Date(timeIntervalSince1970: 1_767_225_600),
    created_by: RestSchema.RelationToUser(id: "user-1"), id: "g1", itinerary_id: "itin-1",
    name: "Approach", revision: 3, speed: 4.5)

  private func line(_ longitudes: Double...) -> GeoJSONLineString {
    GeoJSONLineString(coordinates: longitudes.map { [$0, 45] })
  }

  private func slope(_ ranges: ClosedRange<Int>...) -> [RestSchema.SlopeInfo] {
    ranges.map {
      RestSchema.SlopeInfo(from_index: $0.lowerBound, to_index: $0.upperBound, value: 5)
    }
  }

  @Test("a group collapses at its first member, carrying its identity")
  func collapses() throws {
    let s1 = restSegment("s1", position: 0, geojson: .lineString(line(6, 6.01)))
    let s2 = restSegment(
      "s2", position: 1, geojson: .lineString(line(6.02, 6.03, 6.04)), distance: 1_000, ascent: 100,
      gradient: (-2, 12), groupId: "g1", slope: slope(0...2))
    let s3 = restSegment(
      "s3", position: 2, geojson: .lineString(line(6.05, 6.06, 6.07, 6.08)), distance: 1_000,
      ascent: 50, gradient: (-8, 12), groupId: "g1", slope: slope(0...3))
    let s4 = restSegment("s4", position: 3, geojson: .lineString(line(6.09, 6.1)))
    let projected = applySegmentGroups([s1, s2, s3, s4], groups: [group])

    #expect(projected.map(\.id) == ["s1", "group:g1", "s4"])
    try #require(projected.count == 3)
    #expect(projected[0] == s1)
    #expect(projected[2] == s4)
    let collapsed = projected[1]
    #expect(collapsed.name == "Approach")
    #expect(collapsed.color == "#e9501e")
    #expect(collapsed.itinerary_id == "itin-1")
    #expect(collapsed.group_id == "g1")
    #expect(collapsed.position == 1)
    #expect(collapsed.revision == 3)
    #expect(collapsed.speed == 4.5)
    #expect(collapsed.created_by == group.created_by)
    #expect(collapsed.created_at == group.created_at)
    #expect(collapsed.distance == 2_000)
    #expect(collapsed.ascent == 150)
    #expect(collapsed.gradient_min == -8)
    #expect(collapsed.gradient_max == 12)
    #expect(collapsed.duration == nil)
    #expect(collapsed.description == nil)
    #expect(collapsed.steps == [])
    #expect(
      collapsed.geojson
        == .geometryCollection(
          GeoJSONGeometryCollection(geometries: [
            .lineString(line(6.02, 6.03, 6.04)), .lineString(line(6.05, 6.06, 6.07, 6.08)),
          ])))
    #expect(collapsed.slope_info == slope(0...2, 3...6))
    #expect(collapsed.speed_info == [])
    #expect(collapsed.road_access_info == nil)
  }

  private func access(_ range: ClosedRange<Int>, values: String...) -> RestSchema.RoadAccessInfo {
    RestSchema.RoadAccessInfo(
      from_index: range.lowerBound, to_index: range.upperBound,
      values: values.map { RestSchema.RoadAccessRestrictionType(rawValue: $0) })
  }

  private func namedGroup(_ id: String) -> RestSchema.ItinerarySegmentGroup {
    RestSchema.ItinerarySegmentGroup(
      color: "#1e88e9", created_at: Date(timeIntervalSince1970: 1_767_312_000),
      created_by: RestSchema.RelationToUser(id: "user-1"), id: id, itinerary_id: "itin-1",
      name: id, revision: 1, speed: nil)
  }

  /// A member stating nil adds no range yet its positions still move the next member's on; `[]`
  /// stated by one member makes the group's `[]`, and a group none of whose members states one is
  /// nil.
  @Test("road access ranges move on, and a group is nil only where no member states them")
  func roadAccess() throws {
    let s1 = restSegment(
      "s1", position: 0, geojson: .lineString(line(6, 6.01, 6.02)), groupId: "g1",
      roadAccess: [access(0...1, values: "private")])
    let s2 = restSegment(
      "s2", position: 1, geojson: .lineString(line(6.03, 6.04)), groupId: "g1")
    let s3 = restSegment(
      "s3", position: 2, geojson: .lineString(line(6.05, 6.06, 6.07, 6.08)), groupId: "g1",
      roadAccess: [access(1...3, values: "destination", "permissive")])
    let s4 = restSegment("s4", position: 3, geojson: .lineString(line(6.09, 6.1)), groupId: "g2")
    let s5 = restSegment(
      "s5", position: 4, geojson: .lineString(line(6.11, 6.12)), groupId: "g2", roadAccess: [])
    let s6 = restSegment("s6", position: 5, geojson: .lineString(line(6.13, 6.14)), groupId: "g3")
    let s7 = restSegment("s7", position: 6, geojson: .lineString(line(6.15, 6.16)), groupId: "g3")
    let s8 = restSegment(
      "s8", position: 7, geojson: .lineString(line(6.17, 6.18)),
      roadAccess: [access(0...1, values: "no")])
    let projected = applySegmentGroups(
      [s1, s2, s3, s4, s5, s6, s7, s8], groups: [group, namedGroup("g2"), namedGroup("g3")])

    #expect(projected.map(\.id) == ["group:g1", "group:g2", "group:g3", "s8"])
    try #require(projected.count == 4)
    #expect(
      projected[0].road_access_info
        == [access(0...1, values: "private"), access(6...8, values: "destination", "permissive")])
    #expect(projected[1].road_access_info == [])
    #expect(projected[2].road_access_info == nil)
    #expect(projected[3] == s8)
  }

  @Test("a range a member draws as a MultiLineString moves on by every position of its lines")
  func roadAccessAcrossLines() throws {
    let s1 = restSegment(
      "s1", position: 0,
      geojson: .geometryCollection(
        GeoJSONGeometryCollection(geometries: [
          .lineString(line(6, 6.01)), .multiPoint(GeoJSONMultiPoint(coordinates: [[6, 45]])),
        ])),
      groupId: "g1", roadAccess: [])
    let s2 = restSegment(
      "s2", position: 1,
      geojson: .multiLineString(
        GeoJSONMultiLineString(coordinates: [[[6.02, 45], [6.03, 45]], [[6.04, 45]]])),
      groupId: "g1")
    let s3 = restSegment(
      "s3", position: 2, geojson: .lineString(line(6.05, 6.06)), groupId: "g1",
      roadAccess: [access(0...1, values: "permit")])
    let projected = applySegmentGroups([s1, s2, s3], groups: [group])

    let collapsed = try #require(projected.first)
    #expect(projected.count == 1)
    #expect(collapsed.road_access_info == [access(5...6, values: "permit")])
  }

  @Test("members apart in the chain collapse at the first, and their vias are left out")
  func apart() throws {
    let routed = GeoJSONGeometry.geometryCollection(
      GeoJSONGeometryCollection(geometries: [
        .lineString(line(6, 6.01)), .multiPoint(GeoJSONMultiPoint(coordinates: [[6, 45]])),
      ]))
    let s1 = restSegment("s1", position: 0, geojson: routed, groupId: "g1", slope: slope(0...1))
    let s2 = restSegment("s2", position: 1, geojson: .lineString(line(6.02, 6.03)))
    let s3 = restSegment(
      "s3", position: 2, geojson: .lineString(line(6.04, 6.05)), groupId: "g1", slope: slope(0...1))
    let projected = applySegmentGroups([s1, s2, s3], groups: [group])

    #expect(projected.map(\.id) == ["group:g1", "s2"])
    let collapsed = try #require(projected.first)
    #expect(
      collapsed.geojson
        == .geometryCollection(
          GeoJSONGeometryCollection(geometries: [
            .lineString(line(6, 6.01)), .lineString(line(6.04, 6.05)),
          ])))
    #expect(collapsed.slope_info == slope(0...1, 2...3))
    #expect(collapsed.position == 0)
  }

  @Test("with no group, or no listed one, the chain passes as it is")
  func passes() {
    let segments = [restSegment("s1", position: 0, groupId: "g9"), restSegment("s2", position: 1)]
    #expect(applySegmentGroups(segments, groups: []) == segments)
    #expect(applySegmentGroups(segments, groups: [group]) == segments)
    #expect(segmentGroupIdPrefix == "group:")
  }
}
