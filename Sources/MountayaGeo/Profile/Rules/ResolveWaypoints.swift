import MountayaClient

/// waypointProximityMeters is how near the line must come to a place for the approach to count as
/// a pass, the `proximityMeters` `geo/resolve-waypoints.json` declares. Tight on purpose: it is
/// what separates one pass from the next, so a lollipop's junction is marked twice.
public let waypointProximityMeters: Double = 60

/// waypointBelongingMeters is how far off the line a place may stand and still be one of the
/// itinerary's own, the `belongingMeters` `geo/resolve-waypoints.json` declares: an aid station in a
/// village the trail passes stands a few hundred meters off it.
public let waypointBelongingMeters: Double = 2_000

/// resolveWaypoints places waypoints on the distance axis of a geometry, walked as an elevation
/// series walks it, in meters from its start.
///
/// A waypoint given at a distance stands there. One given at a position stands at every pass of the
/// line within `waypointProximityMeters`, each run of near legs one pass at its nearest point; one
/// with no such pass stands at its single nearest approach within `waypointBelongingMeters`, and
/// one farther than that, or at a position that names no place, is not placed.
///
/// A forward sweep in the order the waypoints are listed gives each its primary pass: the first at
/// or after the pass the waypoint before it took, or its last where every one lies behind. So a
/// loop's start and finish stand at zero and at the total. Any other pass of a waypoint is placed
/// only where no primary pass lies within `waypointProximityMeters` of it. Placements are ordered
/// by distance, then by the order the waypoints are listed, and each is keyed `id#pass`, counting
/// that id's passes from zero.
///
/// Each waypoint is the one at its place in the list: two given the same id are two waypoints, and
/// their keys count passes of that id across both. A distance that is not a number places nothing.
public func resolveWaypoints(_ geometry: GeoJSONGeometry?, waypoints: [ProfileWaypoint])
  -> [PlacedWaypoint]
{
  waypointPasses(geometry, waypoints: waypoints).map {
    PlacedWaypoint(key: $0.key, waypoint: waypoints[$0.listed], distance: $0.distance)
  }
}

/// WaypointPass is one placement of a listed waypoint as `resolveWaypoints(_:waypoints:)` places
/// it: its key, the waypoint's place in the list, its distance, and whether it is the waypoint's
/// primary pass, the one the forward sweep gives it, which the figures stated for a place belong to.
struct WaypointPass: Sendable, Hashable {
  let key: String
  let listed: Int
  let distance: Double
  let isPrimary: Bool
}

/// waypointPasses places waypoints as `resolveWaypoints(_:waypoints:)` states, and says of each
/// placement whether it is its waypoint's primary pass.
func waypointPasses(_ geometry: GeoJSONGeometry?, waypoints: [ProfileWaypoint]) -> [WaypointPass] {
  let legs = walkLegs(linesOf(geometry))
  // Every distance each waypoint could stand at, ascending.
  let candidates: [[Double]] = waypoints.map { waypoint in
    switch waypoint {
    case .atDistance(_, let distance):
      return distance.isNaN ? [] : [distance]
    case .atPosition(_, let position):
      var passes = markerPasses(
        legs, position: position, proximityMeters: waypointProximityMeters)
      if passes.isEmpty {
        // The radius says how many times the line passes a place, not whether it is one of its
        // own: a place with no pass stands at its nearest approach.
        let approaches = markerPasses(
          legs, position: position, proximityMeters: waypointBelongingMeters)
        if let nearest = approaches.min(by: { $0.meters < $1.meters }) {
          passes = [nearest]
        }
      }
      return passes.map(\.distance).sorted()
    }
  }

  // The forward sweep: how far the itinerary has been read to, so a waypoint listed after another
  // cannot be placed before it while it has a later pass to take.
  var primaries: [Double?] = Array(repeating: nil, count: waypoints.count)
  var reached = -Double.infinity
  for (index, list) in candidates.enumerated() {
    guard let latest = list.last else { continue }
    let primary = list.first { $0 >= reached } ?? latest
    primaries[index] = primary
    reached = maximumNumber(reached, primary)
  }
  let claimed = primaries.compactMap { $0 }

  var placed: [(waypoint: Int, distance: Double, isPrimary: Bool)] = []
  for (index, primary) in primaries.enumerated() {
    guard let primary else { continue }
    placed.append((index, primary, true))
    for distance in candidates[index]
    where distance != primary
      && !claimed.contains(where: { abs($0 - distance) <= waypointProximityMeters })
    {
      placed.append((index, distance, false))
    }
  }

  // Ascending by distance, read in total order so -0 stands before 0 as Kotlin's `compareTo` reads
  // them, then by the order the waypoints are listed.
  placed.sort { a, b in
    sameNumber(a.distance, b.distance)
      ? a.waypoint < b.waypoint : a.distance.isTotallyOrdered(belowOrEqualTo: b.distance)
  }
  var passes: [String: Int] = [:]
  return placed.map { placement in
    let waypoint = waypoints[placement.waypoint]
    let pass = passes[waypoint.id, default: 0]
    passes[waypoint.id] = pass + 1
    return WaypointPass(
      key: "\(waypoint.id)#\(pass)", listed: placement.waypoint, distance: placement.distance,
      isPrimary: placement.isPrimary)
  }
}
