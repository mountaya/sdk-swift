/// positionAtMeters is the position a distance in meters along a line, `[longitude, latitude]` in
/// degrees: interpolated between the two vertices whose `cumulativeMeters(_:)` bracket it, in
/// proportion to the distance between them. A distance at or under 0 is the first vertex, and one
/// at or past the line's length the last.
///
/// A leg is interpolated the short way round, as its length is measured: on a leg written 179.9
/// then -179.9 the position halfway is on the antimeridian, never on the prime meridian the two
/// numbers average to. Its longitude continues from the leg's first vertex, past 180 where the leg
/// crosses eastward and below -180 where it crosses westward, which a renderer reads as the same
/// place, and which `wrapLongitude(_:)` brings back where the range the wire writes is needed.
///
/// A vertex that names no place is bridged, as `cumulativeMeters(_:)` reads it, and an altitude is
/// not carried into the answer, which always holds two values. A line with no vertex that names a
/// place, and a distance that is `NaN`, have no position along them, and answer `[NaN, NaN]`, a
/// position that names no place, never `[0, 0]`, which is one.
public func positionAtMeters(_ line: [[Double]], meters: Double) -> [Double] {
  let placed = line.filter(namesPlace)
  guard !placed.isEmpty, !meters.isNaN else { return [.nan, .nan] }
  return positionAlong(cumulativeMeters(placed), meters: meters) { (placed[$0][0], placed[$0][1]) }
}

/// positionAtMeters is the position a distance in meters along the line of `route`, as
/// `positionAtMeters(_:meters:)` places it along `route.line`, to the last digit, read off the
/// route's measure, `FollowedRoute.measured`, taken once as the route was followed: it measures
/// nothing, and finds the leg that holds the distance by a search over the distances measured, so a
/// replay or a host walking a route tick after tick pays a search a tick, never a measurement of
/// the whole line.
///
/// A vertex's distance along the whole line is the one it has along the line of the vertices that
/// name a place alone, the same additions in the same order, so the position is the one the line's
/// own reading answers.
public func positionAtMeters(_ route: FollowedRoute, meters: Double) -> [Double] {
  let placed = route.placed
  guard !placed.indices.isEmpty, !meters.isNaN else { return [.nan, .nan] }
  return positionAlong(placed.meters, meters: meters) {
    (placed.longitudes[$0], placed.latitudes[$0])
  }
}

/// positionAlong is the one placement both readings share: the position `meters` along vertices
/// that each name a place, `vertex` answering the longitude and the latitude of each, measured by
/// `cumulative`, one distance a vertex, at least one, `meters` being a number.
private func positionAlong(
  _ cumulative: [Double], meters: Double, vertex: (Int) -> (longitude: Double, latitude: Double)
) -> [Double] {
  let total = cumulative[cumulative.count - 1]
  if meters <= 0 || total == 0 {
    let first = vertex(0)
    return [first.longitude, first.latitude]
  }
  if meters >= total {
    let last = vertex(cumulative.count - 1)
    return [last.longitude, last.latitude]
  }

  // The last vertex at or before the distance: cumulative[low] <= meters < cumulative[high] holds
  // throughout, so the leg found has a length.
  var low = 0
  var high = cumulative.count - 1
  while low < high - 1 {
    let middle = (low + high) / 2
    if cumulative[middle] <= meters { low = middle } else { high = middle }
  }
  let from = vertex(low)
  let to = vertex(high)
  let ratio = (meters - cumulative[low]) / (cumulative[high] - cumulative[low])
  return [
    from.longitude + longitudeDelta(from: from.longitude, to: to.longitude) * ratio,
    from.latitude + (to.latitude - from.latitude) * ratio,
  ]
}
