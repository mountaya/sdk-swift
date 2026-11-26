/// altitudeBand is the lowest and the highest altitude, in that order, the curve of a series'
/// samples reaches between the distances `from` and `to`, `from` at or before `to`: the samples
/// the stretch holds and the curve read at its two ends, so a stretch shorter than the gap between
/// two samples still has the band between its ends. Only the part of the stretch the samples reach
/// is read. Where two lines meet at an end of the stretch, the band holds the sample of the line
/// the stretch is on.
///
/// Nil for no sample, and for a stretch that lies wholly before the first sample or past the last.
func altitudeBand(_ points: [ElevationPoint], from: Double, to: Double) -> (
  lowest: Double, highest: Double
)? {
  guard let first = points.first, let last = points.last else { return nil }
  let low = maximumNumber(from, first.distance)
  let high = minimumNumber(to, last.distance)
  guard high >= low, let start = startElevationAt(points, distance: low),
    let end = elevationAt(points, distance: high)
  else { return nil }
  let setsOutFrom = startIndexAt(points, distance: low)
  let firstHeld = setsOutFrom < 0 ? firstIndexAtOrPast(points, distance: low) : setsOutFrom
  let lastHeld = firstIndexAtOrPast(points, distance: high)
  var lowest = minimumNumber(start, end)
  var highest = maximumNumber(start, end)
  var index = firstHeld
  while index <= lastHeld, index < points.count {
    let point = points[index]
    if point.distance > high { break }
    lowest = minimumNumber(lowest, point.elevation)
    highest = maximumNumber(highest, point.elevation)
    index += 1
  }
  return (lowest, highest)
}
