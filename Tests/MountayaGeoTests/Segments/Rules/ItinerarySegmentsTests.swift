import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itinerarySegments")
struct ItinerarySegmentsTests {
  private let climb = lineString([6, 45, 1_000], [6, 45.001, 1_100])
  private let drop = lineString([6, 45.001, 1_100], [6, 45.002, 900])

  @Test("the legs read in the order the chain runs, not the order it arrived in")
  func chainOrder() {
    let legs = itinerarySegments(
      [
        restSegment("b", position: 1, geojson: drop), restSegment("c", position: 2),
        restSegment("a", position: 0, geojson: climb),
      ], groups: [])

    #expect(legs.map(\.id) == ["a", "b", "c"])
  }

  /// The figures were computed once over the full track, where an element would read a sampled
  /// copy, so they are carried as the leg's own section.
  @Test("each leg states the server's figures as its own section")
  func serverFigures() throws {
    var segment = restSegment(
      "s1", geojson: climb, distance: 34_369.94, duration: 15_170.16, ascent: 1_531,
      descent: 1_408, altitude: (810, 1_811))
    segment.name = "Tour du Mont Blanc, stage 1"
    segment.color = "#e9501e"

    let legs = itinerarySegments([segment], groups: [])

    #expect(
      legs == [
        ItineraryLeg(
          id: "s1", name: "Tour du Mont Blanc, stage 1", color: "#e9501e", geometry: climb,
          sectionDistance: 34_369.94, sectionAscent: 1_531, sectionDescent: 1_408,
          duration: 15_170.16, altitudeMin: 810, altitudeMax: 1_811)
      ])
  }

  @Test("a figure the server does not state is none, and so is a geometry")
  func unstatedFigures() throws {
    let leg = try #require(itinerarySegments([restSegment("s1")], groups: []).first)

    #expect(leg.geometry == nil)
    #expect(leg.sectionDistance == nil)
    #expect(leg.sectionAscent == nil)
    #expect(leg.sectionDescent == nil)
    #expect(leg.duration == nil)
    #expect(leg.altitudeMin == nil)
    #expect(leg.altitudeMax == nil)
    #expect(leg.color == nil)
    #expect(leg.memberIds.isEmpty)
  }

  /// A zero is a figure the server stated: it never reads as none.
  @Test("a figure of zero is stated as zero")
  func zeroIsStated() throws {
    let leg = try #require(
      itinerarySegments([restSegment("s1", distance: 0, ascent: 0, descent: 0)], groups: []).first)

    #expect(leg.sectionDistance == 0)
    #expect(leg.sectionAscent == 0)
    #expect(leg.sectionDescent == 0)
  }

  @Test("a listed group collapses into one leg carrying its name, its colour and its sums")
  func collapsesGroup() throws {
    let legs = itinerarySegments(
      [
        restSegment(
          "a", position: 0, geojson: climb, distance: 1_000, duration: 600, ascent: 100, descent: 0,
          altitude: (1_000, 1_300), groupId: "g"),
        restSegment(
          "b", position: 1, geojson: drop, distance: 500, duration: 300, ascent: 50, descent: 20,
          altitude: (1_200, 1_450), groupId: "g"),
        restSegment("c", position: 2, geojson: climb, distance: 200),
      ],
      groups: [restGroup("g", name: "The col", color: "#7048e8")])

    try #require(legs.count == 2)
    #expect(
      legs[0]
        == ItineraryLeg(
          id: "group:g", memberIds: ["a", "b"], name: "The col", color: "#7048e8",
          geometry: collectionOf(climb, drop), sectionDistance: 1_500, sectionAscent: 150,
          sectionDescent: 20, duration: 900, altitudeMin: 1_000, altitudeMax: 1_450))
    #expect(legs[1].id == "c")
    #expect(legs[1].memberIds.isEmpty)
  }

  @Test("a collapsed leg names its members in chain order, and no other leg names a member")
  func membersInChainOrder() {
    let legs = itinerarySegments(
      [
        restSegment("b", position: 2, geojson: drop, groupId: "g"),
        restSegment("plain", position: 0, geojson: climb),
        restSegment("a", position: 1, geojson: climb, groupId: "g"),
        restSegment("orphan", position: 3, geojson: drop, groupId: "unlisted"),
      ],
      groups: [restGroup("g", name: "The col")])

    #expect(legs.map(\.id) == ["plain", "group:g", "orphan"])
    #expect(legs.map(\.memberIds) == [[], ["a", "b"], []])
  }

  @Test("a segment of a group the itinerary does not list is a leg of its own")
  func unlistedGroup() {
    let legs = itinerarySegments(
      [restSegment("s1", geojson: climb, distance: 1_000, groupId: "g9")], groups: [])

    #expect(legs == [ItineraryLeg(id: "s1", name: "s1", geometry: climb, sectionDistance: 1_000)])
  }

  /// A collapsed run lays its members' lines end to end. Losing them would give the leg no span and
  /// slide every later leg's stretch back.
  @Test("a collapsed leg keeps its members' lines, so its span measures its own stretch")
  func collapsedGeometry() throws {
    let legs = itinerarySegments(
      [
        restSegment("a", position: 0, geojson: climb, groupId: "g"),
        restSegment("b", position: 1, geojson: drop, groupId: "g"),
      ],
      groups: [restGroup("g")])

    let leg = try #require(legs.first)
    #expect(buildElevationSeries(leg.geometry).totalDistance > 0)
  }

  /// A real segment may carry an id that reads like a group's: only a listed group's members are
  /// collapsed, so it lists no member.
  @Test("a segment whose own id reads like a group's lists no member")
  func lookalikeId() {
    let legs = itinerarySegments(
      [restSegment("group:g", position: 0), restSegment("a", position: 1, groupId: "g")],
      groups: [restGroup("g")])

    #expect(legs.map(\.id) == ["group:g", "group:g"])
    #expect(legs.map(\.memberIds) == [[], ["a"]])
  }

  @Test("an itinerary of no segment has no leg, with or without groups")
  func emptyChain() {
    #expect(itinerarySegments([], groups: []).isEmpty)
    #expect(itinerarySegments([], groups: [restGroup("g")]).isEmpty)
  }
}
