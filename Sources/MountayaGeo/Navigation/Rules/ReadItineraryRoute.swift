import MountayaClient

/// readItineraryRoute joins an itinerary's segments, as REST answers them, into the one route a
/// traveller follows over all of them (`geo.navigation.itinerary-route`), or answers nil where no
/// segment holds a line.
///
/// The segments are taken in chain order, by `position`, two at one position in the order they are
/// listed, and so are the waypoints. A segment's line is its LineString: its geometry where it is
/// one, else the first one its GeometryCollection holds, the MultiPoint beside it left out. A
/// segment holding none, or one of no vertex, holds no line and is passed over, its duration with
/// it. Each segment holding a line is followed as `followedRouteOf(_:)` follows a route: by its own
/// steps, read as `readItineraryDirectionsSteps(_:coordinateCount:)` reads them, where they tile its
/// line, and otherwise as a departure over its line, carrying its own duration and the line's
/// great-circle length, then an arrival on its last vertex.
///
/// The arrival of every segment but the last, where its last step is a `goal`, is said as a
/// `waypoint`, since the traveller arrives only where the route ends: the step keeps its range and
/// its figures, and its name is that of the waypoint standing where the segment's line ends, the
/// nearest whose Point lies within `waypointProximityMeters` of that vertex, as
/// `haversineMeters(from:to:)` measures it, of two as near the first in chain order, among those
/// named other than the empty text and `-`, and none where none stands within reach.
///
/// The lines are laid end to end, each vertex as written. A line that starts on the very longitude
/// and latitude the one before it ends on drops that vertex, so the joint is one vertex, the earlier
/// line's, its elevation included; one that starts anywhere else keeps it, and its first step
/// reaches back to the vertex the line before it ends on, so the leg across the gap is that step's.
/// Every step is moved on by the index its line starts at in the joined line. A departure naming no
/// way right after a waypoint says nothing the waypoint did not, since a step carries no heading, so
/// it is folded into the waypoint, which runs on to where the departure ends, their distances and
/// their durations summed, each unknown where either is; one naming a way is kept. The joined steps
/// tile the joined line.
///
/// The route's duration is the segments' durations summed in chain order, unknown where a segment
/// holding a line states none.
public func readItineraryRoute(
  _ segments: [RestSchema.ItinerarySegment], waypoints: [RestSchema.ItineraryWaypoint]
) -> NavigationRoute? {
  let named = chainOrder(waypoints, by: \.position).compactMap {
    waypoint -> (place: [Double], name: String)? in
    guard case .point(let point)? = waypoint.geojson, namesPlace(point.coordinates),
      let name = wayName(waypoint.name)
    else { return nil }
    return (point.coordinates, name)
  }
  var parts: [(line: [[Double]], steps: [NavigationStep], duration: Double?)] = []
  for segment in chainOrder(segments, by: \.position) {
    guard let line = firstLineString(segment.geojson), !line.isEmpty else { continue }
    let reading = readItineraryDirectionsSteps(segment.steps, coordinateCount: line.count)
    guard
      let followed = followedRouteOf(
        NavigationRoute(line: line, steps: reading.steps, duration: segment.duration))
    else { continue }
    parts.append((line, followed.steps, segment.duration))
  }
  guard !parts.isEmpty else { return nil }

  // Every arrival but the route's own is a waypoint, named by the one at the end of its line.
  for index in parts.indices.dropLast() {
    guard let last = parts[index].steps.indices.last,
      isManeuver(parts[index].steps[last], ofType: .goal)
    else { continue }
    parts[index].steps[last].maneuver = .waypoint
    parts[index].steps[last].name = waypointName(at: parts[index].line.last, among: named)
  }

  var line: [[Double]] = []
  var steps: [NavigationStep] = []
  var duration: Double? = 0
  for part in parts {
    duration = duration.flatMap { total in part.duration.map { total + $0 } }
    var moved = part.steps
    if let end = line.last {
      let joins = samePlace(part.line[0], end)
      let offset = joins ? line.count - 1 : line.count
      line.append(contentsOf: joins ? Array(part.line.dropFirst()) : part.line)
      for index in moved.indices {
        moved[index].fromIndex += offset
        moved[index].toIndex += offset
      }
      // Across a gap, the first step reaches back to the vertex the line before it ends on.
      if !joins, !moved.isEmpty {
        moved[0].fromIndex = offset - 1
      }
    } else {
      line = part.line
    }
    if let before = steps.indices.last, isManeuver(steps[before], ofType: .waypoint),
      let first = moved.first, isManeuver(first, ofType: .depart), first.name == nil
    {
      steps[before].toIndex = first.toIndex
      steps[before].distance = summed(steps[before].distance, first.distance)
      steps[before].duration = summed(steps[before].duration, first.duration)
      moved.removeFirst()
    }
    steps.append(contentsOf: moved)
  }
  return NavigationRoute(line: line, steps: steps, duration: duration)
}

/// chainOrder is `items` by `position`, two at one position in the order they are listed: a sort
/// that keeps that order whatever the sort's own stability.
private func chainOrder<Item>(_ items: [Item], by position: (Item) -> Int) -> [Item] {
  items.enumerated()
    .sorted { (position($0.element), $0.offset) < (position($1.element), $1.offset) }
    .map(\.element)
}

/// firstLineString is a segment's line: its geometry's coordinates where it is a LineString, else
/// those of the first LineString its GeometryCollection holds, at any depth, and nil where it holds
/// none. A MultiLineString is no line of a segment's.
private func firstLineString(_ geometry: GeoJSONGeometry?) -> [[Double]]? {
  switch geometry {
  case .lineString(let line)?:
    return line.coordinates
  case .geometryCollection(let collection)?:
    for member in collection.geometries {
      if let line = firstLineString(member) { return line }
    }
    return nil
  case nil, .point?, .multiPoint?, .multiLineString?, .polygon?, .multiPolygon?:
    return nil
  }
}

/// waypointName is the name of the waypoint standing at `vertex`: the nearest of `named` within
/// `waypointProximityMeters` of it, of two as near the first, and nil where none stands within
/// reach or the vertex names no place.
private func waypointName(at vertex: [Double]?, among named: [(place: [Double], name: String)])
  -> String?
{
  guard let vertex, namesPlace(vertex) else { return nil }
  var nearest: (meters: Double, name: String)?
  for waypoint in named {
    let meters = haversineMeters(from: vertex, to: waypoint.place)
    if meters <= waypointProximityMeters, nearest.map({ meters < $0.meters }) ?? true {
      nearest = (meters, waypoint.name)
    }
  }
  return nearest?.name
}

/// samePlace is true where two vertices stand on the very same longitude and latitude, whatever
/// their elevations, and false where either names no such pair.
private func samePlace(_ a: [Double], _ b: [Double]) -> Bool {
  a.count >= 2 && b.count >= 2 && a[0] == b[0] && a[1] == b[1]
}

/// isManeuver is true where a step's maneuver is spelled exactly as `maneuver` is.
private func isManeuver(_ step: NavigationStep, ofType maneuver: RestSchema.ManeuverType) -> Bool {
  sameText(step.maneuver.rawValue, maneuver.rawValue)
}

/// summed is two figures added, unknown where either is.
private func summed(_ a: Double?, _ b: Double?) -> Double? {
  guard let a, let b else { return nil }
  return a + b
}
