/// elevationAt is the altitude the curve of a series' samples stands at `distance` meters from the
/// itinerary's start, read on the straight line between the two samples either side of it, the
/// line a chart draws. A distance that is a sample's own reads that sample, the first of those
/// standing there, short of the last sample's distance, which reads the last sample; one before
/// the first sample or past the last reads that end's altitude. Nil for no sample, and for a
/// distance that is not a number.
func elevationAt(_ points: [ElevationPoint], distance: Double) -> Double? {
  guard let first = points.first, let last = points.last, !distance.isNaN else { return nil }
  if distance <= first.distance { return first.elevation }
  if distance >= last.distance { return last.elevation }
  let index = firstIndexAtOrPast(points, distance: distance)
  guard index > 0, index < points.count else { return nil }
  let after = points[index]
  let before = points[index - 1]
  if after.distance == distance { return after.elevation }
  let run = after.distance - before.distance
  let ratio = run > 0 ? (distance - before.distance) / run : 0
  return before.elevation + (after.elevation - before.elevation) * ratio
}

/// firstIndexAtOrPast is the index of the first sample standing at or past `distance`, or the
/// count of them where every one stands before it, found by halving. A distance that is not a
/// number answers 0.
func firstIndexAtOrPast(_ points: [ElevationPoint], distance: Double) -> Int {
  var low = 0
  var high = points.count
  while low < high {
    let middle = (low + high) / 2
    if points[middle].distance < distance {
      low = middle + 1
    } else {
      high = middle
    }
  }
  return low
}

/// startIndexAt is the index of the sample a stretch starting at `distance` sets out from: the last
/// sample standing at that distance, or -1 where none stands there and the start is read between
/// two. Where two lines meet, the earlier line's last sample and the later line's first stand at
/// one distance, at two places and two altitudes, and a stretch starting there is on the later
/// line.
func startIndexAt(_ points: [ElevationPoint], distance: Double) -> Int {
  var index = firstIndexAtOrPast(points, distance: distance)
  guard index < points.count, points[index].distance == distance else { return -1 }
  while index + 1 < points.count, points[index + 1].distance == distance {
    index += 1
  }
  return index
}

/// startElevationAt is the altitude a stretch starting at `distance` sets out from, as
/// `startIndexAt(_:distance:)` reads it.
func startElevationAt(_ points: [ElevationPoint], distance: Double) -> Double? {
  let index = startIndexAt(points, distance: distance)
  return index >= 0 ? points[index].elevation : elevationAt(points, distance: distance)
}
