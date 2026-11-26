/// nearestSampleIndex is the place in a series of the sample nearest `distance` meters from the
/// itinerary's start, found by halving (`geo.profile.scrub-grid`): the earlier of two standing
/// equally near, so a scrub that lands exactly between two resolves the same way every time, and
/// the first or the last for a distance before or past them. Nil for a series with no sample.
public func nearestSampleIndex(_ points: [ElevationPoint], distance: Double) -> Int? {
  guard !points.isEmpty else { return nil }
  var low = 0
  var high = points.count - 1
  while low < high {
    let middle = (low + high) / 2
    if points[middle].distance < distance {
      low = middle + 1
    } else {
      high = middle
    }
  }
  let before = low > 0 ? low - 1 : 0
  let afterGap = abs(points[low].distance - distance)
  let beforeGap = abs(points[before].distance - distance)
  return beforeGap <= afterGap ? before : low
}
