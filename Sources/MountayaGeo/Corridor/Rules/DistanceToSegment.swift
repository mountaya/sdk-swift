import Foundation

/// distanceToSegment is the shortest distance from a point to the segment from `start` to `end`,
/// in the plane of the positions as written: their longitudes and latitudes read as plain
/// coordinates, so the answer is in degrees, with no cosine and no wrap. A degenerate segment, its
/// two ends one vertex, answers the distance to that vertex.
///
/// It answers what `geo/corridor.json`'s cases answer, which is planar degrees; the distance on
/// the ground in meters is `metersToRoute(_:lines:)`. A position that names no place, short of a
/// longitude or a latitude or with either not finite, answers `NaN`.
public func distanceToSegment(_ point: [Double], start: [Double], end: [Double]) -> Double {
  guard namesPlace(point), namesPlace(start), namesPlace(end) else { return .nan }
  return planarDistanceToSegment(
    pointX: point[0], pointY: point[1],
    startX: start[0], startY: start[1],
    endX: end[0], endY: end[1]
  )
}

/// planarDistanceToSegment is the shortest distance in a plane from a point to a segment: to the
/// foot of the perpendicular where it falls on the segment, to the nearer end where it falls past
/// one, and to the start where the segment is one point. The fraction along the segment is held
/// within [0, 1] with `NaN` kept.
func planarDistanceToSegment(
  pointX: Double, pointY: Double,
  startX: Double, startY: Double,
  endX: Double, endY: Double
) -> Double {
  planarDistanceToFoot(
    pointX: pointX, pointY: pointY, startX: startX, startY: startY, endX: endX, endY: endY,
    fraction: planarFootFraction(
      pointX: pointX, pointY: pointY, startX: startX, startY: startY, endX: endX, endY: endY))
}

/// planarFootFraction is where the foot of a point stands on a segment in a plane, as a fraction
/// of the segment from its start: the projection onto the line through it, held within [0, 1] with
/// `NaN` kept, so a point past an end has its foot on that end. A segment that is one point has
/// its foot there, at 0.
///
/// It is the one statement of the projection `planarDistanceToSegment` measures and a traveller's
/// progress along a route stands on, so the two read one foot.
func planarFootFraction(
  pointX: Double, pointY: Double,
  startX: Double, startY: Double,
  endX: Double, endY: Double
) -> Double {
  let spanX = endX - startX
  let spanY = endY - startY
  let lengthSquared = spanX * spanX + spanY * spanY
  if lengthSquared == 0 { return 0 }
  return clampNumber(
    ((pointX - startX) * spanX + (pointY - startY) * spanY) / lengthSquared, to: 0...1)
}

/// planarDistanceToFoot is the distance in a plane from a point to the place `fraction` of the
/// way along a segment from its start.
func planarDistanceToFoot(
  pointX: Double, pointY: Double,
  startX: Double, startY: Double,
  endX: Double, endY: Double,
  fraction: Double
) -> Double {
  hypot(
    pointX - (startX + fraction * (endX - startX)), pointY - (startY + fraction * (endY - startY)))
}
