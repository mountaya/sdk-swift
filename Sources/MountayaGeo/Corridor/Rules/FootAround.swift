import Foundation

/// metersPerDegreeLongitudeAt is the ground length in meters of one degree of longitude in the
/// local plane placed around a point at a latitude, in degrees: the mean sphere's degree times the
/// cosine of the latitude.
func metersPerDegreeLongitudeAt(_ latitude: Double) -> Double {
  metersPerDegreeMeanSphere * cos(latitude * radiansPerDegree)
}

/// footAround places the segment from `from` to `to` in the local plane around `point`, as a
/// corridor places every segment it measures, and answers the point's foot on it: the foot's
/// distance from the point in ground meters, and the fraction of the segment it stands at from
/// `from`, in [0, 1].
///
/// The plane's degree of latitude is `metersPerDegreeMeanSphere`, and its degree of longitude
/// `metersPerDegreeLongitude`, `metersPerDegreeLongitudeAt(_:)` the point's latitude, handed in so
/// a walk over many segments reads the cosine once. A longitude is read as an angle, and the
/// segment is kept in one piece: its first end is placed the short way round from the point and
/// its second the short way round from the first. Where the segment runs past the meridian half a
/// turn from the point, the stretch beyond it is nearer the point written a whole turn that way,
/// and the foot there is the one answered where it is the nearer, the direct one where the two are
/// as near.
///
/// It is the one placement of a segment that `metersToRoute(_:lines:)` measures and a traveller's
/// progress stands on, so a traveller is off a route by the distance their progress is read at.
/// Every position names a place here: a caller skips a vertex that names none, as every walk of a
/// line does. The answer is a tuple, so a walk over a long line allocates nothing per segment.
func footAround(
  _ point: [Double], metersPerDegreeLongitude: Double, from: [Double], to: [Double]
) -> (distance: Double, fraction: Double) {
  footAround(
    longitude: point[0], latitude: point[1], metersPerDegreeLongitude: metersPerDegreeLongitude,
    fromLongitude: from[0], fromLatitude: from[1], toLongitude: to[0], toLatitude: to[1])
}

/// footAround is the foot of the point at `longitude` and `latitude` on the segment between the
/// two positions named by their longitudes and latitudes, as the positions themselves read it: the
/// one placement, read off numbers, which a walk over a route's flattened vertices hands it
/// (`FollowedRoute`) with no array to retain for each.
func footAround(
  longitude: Double, latitude: Double, metersPerDegreeLongitude: Double,
  fromLongitude: Double, fromLatitude: Double, toLongitude: Double, toLatitude: Double
) -> (distance: Double, fraction: Double) {
  // Both ends the short way round from the point, then the second moved by the whole turn that
  // brings it within half a turn of the first, so the segment stays in one piece.
  let startDegrees = longitudeDelta(from: longitude, to: fromLongitude)
  let shortDegrees = longitudeDelta(from: longitude, to: toLongitude)
  let step = shortDegrees - startDegrees
  let endDegrees =
    abs(step) <= longitudeLimit ? shortDegrees : shortDegrees - signum(step) * degreesPerTurn

  let startX = startDegrees * metersPerDegreeLongitude
  let startY = (fromLatitude - latitude) * metersPerDegreeMeanSphere
  let endX = endDegrees * metersPerDegreeLongitude
  let endY = (toLatitude - latitude) * metersPerDegreeMeanSphere
  var fraction = planarFootFraction(
    pointX: 0, pointY: 0, startX: startX, startY: startY, endX: endX, endY: endY)
  var distance = planarDistanceToFoot(
    pointX: 0, pointY: 0, startX: startX, startY: startY, endX: endX, endY: endY,
    fraction: fraction)

  // The segment runs past the meridian half a turn from the point: the stretch beyond it is
  // nearer the point written a whole turn that way.
  if abs(endDegrees) > longitudeLimit {
    let turnedX = signum(endDegrees) * degreesPerTurn * metersPerDegreeLongitude
    let turnedFraction = planarFootFraction(
      pointX: turnedX, pointY: 0, startX: startX, startY: startY, endX: endX, endY: endY)
    let turnedDistance = planarDistanceToFoot(
      pointX: turnedX, pointY: 0, startX: startX, startY: startY, endX: endX, endY: endY,
      fraction: turnedFraction)
    if turnedDistance < distance {
      fraction = turnedFraction
      distance = turnedDistance
    }
  }
  return (distance, fraction)
}

/// signum is 1 for a number above zero, -1 for one under it, and the number itself for either
/// zero and for `NaN`.
private func signum(_ value: Double) -> Double {
  if value > 0 { return 1 }
  if value < 0 { return -1 }
  return value
}
