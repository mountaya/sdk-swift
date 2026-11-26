import Foundation
import MountayaClient
import MountayaGeo

/// restItinerary is an itinerary as the REST API answers one, holding the segments, waypoints and
/// groups a test states and a placeholder for every member the rules never read.
func restItinerary(
  _ id: String = "itinerary",
  segments: [RestSchema.ItinerarySegment] = [],
  waypoints: [RestSchema.ItineraryWaypoint] = [],
  groups: [RestSchema.ItinerarySegmentGroup] = []
) -> RestSchema.ItineraryWithDetails {
  RestSchema.ItineraryWithDetails(
    activity_id: "hiking", ascent: nil,
    count: RestSchema.ItineraryCount(
      groups: groups.count, segments: segments.count, waypoints: waypoints.count),
    created_at: Date(timeIntervalSince1970: 0), created_by: RestSchema.RelationToUser(id: "user"),
    description: nil, distance: nil, id: id, is_private: false, is_verified: false, name: id,
    organization_id: nil, etag: "etag", revision: 1, status: .draft,
    updated_at: Date(timeIntervalSince1970: 0), groups: groups, has_unpublished_changes: false,
    published_at: nil, segments: segments, waypoints: waypoints)
}

/// restGroup is a segment group as the REST API answers one, named and coloured as a test states.
func restGroup(_ id: String, name: String? = nil, color: String = "#7048e8")
  -> RestSchema.ItinerarySegmentGroup
{
  RestSchema.ItinerarySegmentGroup(
    color: color, created_at: Date(timeIntervalSince1970: 0),
    created_by: RestSchema.RelationToUser(id: "user"), id: id, itinerary_id: "itinerary",
    name: name ?? id, revision: 1, speed: nil)
}

/// restPlace is a waypoint as the REST API answers one, at the geometry a test states, with the
/// name, colour, icon and details it states and a placeholder for every other member.
func restPlace(
  _ id: String,
  position: Int = 0,
  geojson: GeoJSONGeometry?,
  name: String? = nil,
  color: String? = nil,
  icon: RestSchema.WaypointIcon? = nil,
  configure: (inout RestSchema.ItineraryWaypoint) -> Void = { _ in }
) -> RestSchema.ItineraryWaypoint {
  RestSchema.ItineraryWaypoint(
    amenities: [], color: color, contact: nil, created_at: Date(timeIntervalSince1970: 0),
    created_by: RestSchema.RelationToUser(id: "user"), description: nil, geojson: geojson,
    icon: icon, id: id, itinerary_id: "itinerary", media: nil, mode: .poi,
    name: name, position: position, properties: nil, revision: 1, timing: nil,
    configure: configure)
}

/// pointAt is the Point at the position a test writes.
func pointAt(_ position: Double...) -> GeoJSONGeometry {
  .point(GeoJSONPoint(coordinates: position))
}

/// collectionOf is the GeometryCollection of the geometries a test writes, the wrapper a waypoint's
/// point is stored in.
func collectionOf(_ geometries: GeoJSONGeometry...) -> GeoJSONGeometry {
  .geometryCollection(GeoJSONGeometryCollection(geometries: geometries))
}

/// ScriptedReads stands for the clients an itinerary is read through. Each read a source is asked
/// for is recorded in the order it was sent and held open until the test answers or fails it.
///
/// Its sources are main-actor closures, so every step of an engine over them runs on the main actor
/// in order, and `settle()` lets a step land.
@MainActor
final class ScriptedReads {
  /// Read is one read a source was asked for.
  struct Read {
    let itineraryId: String
    let surface: RestSchema.ReadSurface?
    let client: String
    let continuation: CheckedContinuation<RestSchema.ItineraryWithDetails, any Error>
  }

  /// Failed is the failure a read is failed with unless a test names another.
  struct Failed: Error, Equatable {
    let index: Int
  }

  private(set) var sent: [Read] = []
  private var settled: Set<Int> = []

  /// source is the source of the client `client`, which records each read it is asked for and
  /// holds it open.
  func source(_ client: String = "a") -> ItinerarySource {
    { @MainActor [self] itineraryId, surface in
      try await withCheckedThrowingContinuation { continuation in
        sent.append(
          Read(
            itineraryId: itineraryId, surface: surface, client: client,
            continuation: continuation))
      }
    }
  }

  /// asked is every read sent, as `client:itinerary:surface`, the draft spelled `draft`.
  var asked: [String] {
    sent.map { "\($0.client):\($0.itineraryId):\($0.surface?.rawValue ?? "draft")" }
  }

  /// answer answers read `index` with `itinerary`, by default one whose one segment, `read-<index>`,
  /// names the read and is `distance` meters long.
  func answer(
    _ index: Int, with itinerary: RestSchema.ItineraryWithDetails? = nil, distance: Double = 1_000
  ) {
    guard index < sent.count, settled.insert(index).inserted else { return }
    let read = sent[index]
    read.continuation.resume(
      returning: itinerary ?? answered(index, itineraryId: read.itineraryId, distance: distance))
  }

  /// fail fails read `index` with `error`, by default `Failed` naming the read.
  func fail(_ index: Int, with error: (any Error)? = nil) {
    guard index < sent.count, settled.insert(index).inserted else { return }
    sent[index].continuation.resume(throwing: error ?? Failed(index: index))
  }

  /// drain fails every read still open, so no task is left waiting when a test ends.
  func drain() {
    for index in sent.indices {
      fail(index)
    }
  }

  /// answered is the itinerary read `index` answers: one segment named by the read.
  private func answered(_ index: Int, itineraryId: String, distance: Double)
    -> RestSchema.ItineraryWithDetails
  {
    restItinerary(
      itineraryId,
      segments: [
        restSegment(
          "read-\(index)", position: 0, geojson: lineString([6, 45], [6.01, 45]),
          distance: distance)
      ])
  }
}

/// settle lets every read answered so far land and every engine it moves be told: each turn of the
/// main actor runs the jobs queued before it, and a step queues a chain of a few at most.
@MainActor
func settle() async {
  for _ in 0..<8 {
    await Task.yield()
  }
}

/// shownRead is the read whose answer a state shows, read off its first leg's id, or nil where it
/// shows none.
func shownRead(_ state: ItineraryResource) -> Int? {
  guard case .resolved(let itinerary) = state, let leg = itinerary.legs.first,
    leg.id.hasPrefix("read-")
  else { return nil }
  return Int(leg.id.dropFirst("read-".count))
}
