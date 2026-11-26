/// gradeAt is how steep an itinerary is `distance` meters from its start, in degrees, negative for a
/// descent (`geo.profile.grade-at`): the slope across the `gradeWindowMeters` of curve centred on
/// the distance, cut to the part of that window the samples hold, each end read on the line between
/// the two samples either side of it, so the run is the window's width whatever the samples'
/// spacing and two noisy samples ten meters apart are no cliff.
///
/// Nil where the window holds no length of the curve: a series of fewer than two samples, and a
/// distance farther from the curve than half the window.
public func gradeAt(_ points: [ElevationPoint], distance: Double) -> Double? {
  guard let first = points.first, let last = points.last else { return nil }
  let half = gradeWindowMeters / 2
  let from = maximumNumber(first.distance, distance - half)
  let to = minimumNumber(last.distance, distance + half)
  guard to > from, let start = elevationAt(points, distance: from),
    let end = elevationAt(points, distance: to)
  else {
    return nil
  }
  return convertSlope((end - start) / (to - from), from: .ratio, to: .degrees)
}
