import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ResolvedItinerary")
struct ResolvedItineraryTests {
  private let first = lineString([6, 45, 1_000], [6, 45.001, 1_100])
  private let second = lineString([6, 45.001, 1_100], [6, 45.002, 1_200])

  private func itinerary(distance: Double = 1_000) -> RestSchema.ItineraryWithDetails {
    var hut = restPlace(
      "hut", position: 1, geojson: collectionOf(pointAt(6, 45.001, 1_100)), name: "Hut")
    hut.timing = RestSchema.WaypointTiming { $0.stop_duration = 900 }
    return restItinerary(
      segments: [
        restSegment("b", position: 1, geojson: second, distance: distance, ascent: 100),
        restSegment("a", position: 0, geojson: first, distance: 500, ascent: 50, groupId: "g"),
      ],
      waypoints: [
        hut, restPlace("start", position: 0, geojson: collectionOf(pointAt(6, 45)), name: "Start"),
      ],
      groups: [restGroup("unused")])
  }

  @Test("every projection is read from one itinerary at once, in chain order")
  func projections() {
    let resolved = ResolvedItinerary(itinerary())

    #expect(resolved.geometry == collectionOf(first, second))
    #expect(resolved.legs.map(\.id) == ["a", "b"])
    #expect(resolved.waypoints.map(\.id) == ["start", "hut"])
    #expect(resolved.characteristics.distance == 1_500)
    #expect(resolved.characteristics.ascent == 150)
  }

  @Test("the figures are the profile's own, the waypoints' planned stops included")
  func figures() {
    let wire = itinerary()

    #expect(
      ResolvedItinerary(wire).characteristics
        == profileCharacteristics(
          inChainOrder(wire.segments, position: \.position), waypoints: wire.waypoints))
    #expect(ResolvedItinerary(wire).characteristics.stopDuration == 900)
  }

  @Test("each projection is the rule's own")
  func rulesOwn() {
    let wire = itinerary()
    let resolved = ResolvedItinerary(wire)

    #expect(resolved.legs == itinerarySegments(wire.segments, groups: wire.groups))
    #expect(resolved.waypoints == itineraryWaypoints(wire.waypoints))
    #expect(resolved.geometry == itineraryGeometry(wire.segments))
  }

  @Test("an itinerary of no segment has no geometry, no leg and no figure")
  func empty() {
    let resolved = ResolvedItinerary(restItinerary())

    #expect(resolved.geometry == nil)
    #expect(resolved.legs.isEmpty)
    #expect(resolved.waypoints.isEmpty)
    #expect(resolved.characteristics.distance == nil)
    #expect(resolved.characteristics.durationPartial == false)
  }

  @Test("an answer and its copies are equal, two projections alike are equal, and hash alike")
  func equality() {
    let resolved = ResolvedItinerary(itinerary())
    let copy = resolved
    let again = ResolvedItinerary(itinerary())

    #expect(resolved == copy)
    #expect(resolved == again)
    #expect(resolved.hashValue == again.hashValue)
    #expect(resolved != ResolvedItinerary(itinerary(distance: 2_000)))
  }
}
