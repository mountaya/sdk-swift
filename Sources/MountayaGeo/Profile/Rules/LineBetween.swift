import MountayaClient

/// lineBetween is the stretch of an itinerary between `from` and `to` meters from its start, cut
/// from its series as the line a map lights (`geo.profile.line-between`): the samples the chart
/// drew, so a leg emphasised on a map is the leg stated in the row beside it.
///
/// The stretch is held to the samples, so one past them stops at the first or the last. The line
/// starts where the stretch starts and ends where it ends, each read on the line between the two
/// samples either side of it, the short way round across the antimeridian with its longitude
/// brought within [-180, 180], and holds every sample strictly between the two; so a stretch shorter
/// than the gap between two samples is still a line. Where two lines meet at one distance, a
/// stretch starting there starts on the later line and one ending there ends on the earlier. Nil
/// where the stretch holds no length of the curve: given backwards, of no length or wholly past the
/// samples, and for an empty series.
public func lineBetween(_ points: [ElevationPoint], from: Double, to: Double) -> GeoJSONGeometry? {
  guard let first = points.first, let last = points.last else { return nil }
  let low = maximumNumber(from, first.distance)
  let high = minimumNumber(to, last.distance)
  guard high > low else { return nil }
  let setsOutFrom = startIndexAt(points, distance: low)
  let start =
    setsOutFrom >= 0
    ? [points[setsOutFrom].lngLat[0], points[setsOutFrom].lngLat[1]]
    : positionAt(points, distance: low)
  guard let start, let end = positionAt(points, distance: high) else { return nil }
  var coordinates = [start]
  var index = firstIndexAtOrPast(points, distance: low)
  while index < points.count, points[index].distance < high {
    if points[index].distance > low {
      coordinates.append([points[index].lngLat[0], points[index].lngLat[1]])
    }
    index += 1
  }
  coordinates.append(end)
  return .lineString(GeoJSONLineString(coordinates: coordinates))
}

/// positionAt is where the curve of a series' samples stands on the ground `distance` meters from
/// the itinerary's start, `[longitude, latitude]`, read on the line between the two samples either
/// side of it as `elevationAt(_:distance:)` reads the altitude there, the short way round across the
/// antimeridian, its longitude brought within [-180, 180]. Nil for no sample, and for a distance
/// that is not a number.
func positionAt(_ points: [ElevationPoint], distance: Double) -> [Double]? {
  guard let first = points.first, let last = points.last, !distance.isNaN else { return nil }
  if distance <= first.distance { return [first.lngLat[0], first.lngLat[1]] }
  if distance >= last.distance { return [last.lngLat[0], last.lngLat[1]] }
  let index = firstIndexAtOrPast(points, distance: distance)
  guard index > 0, index < points.count else { return nil }
  let after = points[index]
  let before = points[index - 1]
  if after.distance == distance { return [after.lngLat[0], after.lngLat[1]] }
  let run = after.distance - before.distance
  let ratio = run > 0 ? (distance - before.distance) / run : 0
  guard ratio != 0 else { return [before.lngLat[0], before.lngLat[1]] }
  return [
    wrapLongitudePastRange(
      before.lngLat[0] + longitudeDelta(from: before.lngLat[0], to: after.lngLat[0]) * ratio),
    before.lngLat[1] + (after.lngLat[1] - before.lngLat[1]) * ratio,
  ]
}
