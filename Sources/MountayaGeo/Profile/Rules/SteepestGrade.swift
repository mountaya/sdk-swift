/// steepestGrade is the steepest ascending `gradeWindowMeters` of the stretch of a series' samples
/// between the distances `from` and `to`, `from` at or before `to`, in degrees, never under 0.
///
/// Every run measured is the window's full width, each end read on the curve between the two
/// samples either side of it, so two samples closer together than the noise they carry never set
/// the figure. The curve is straight between samples, so the steepest run starts or ends on a
/// sample or at an end of the stretch, and those are the runs measured, in two forward passes. A
/// stretch shorter than the window is measured end to end. Where two lines meet at an end of the
/// stretch, a run reads the line the stretch is on.
///
/// Nil for no sample, and for a stretch that holds no length of the curve.
func steepestGrade(_ points: [ElevationPoint], from: Double, to: Double) -> Double? {
  guard let first = points.first, let last = points.last else { return nil }
  let low = maximumNumber(from, first.distance)
  let high = minimumNumber(to, last.distance)
  guard high > low, let lowest = startElevationAt(points, distance: low),
    let highest = elevationAt(points, distance: high)
  else { return nil }

  let run = minimumNumber(high - low, gradeWindowMeters)
  let inside = firstIndexAtOrPast(points, distance: low)

  // The runs that start at the stretch's own start and at each sample. One that reaches the
  // stretch's end reads the end's own altitude.
  var ahead = CurveCursor(points: points, startIndex: inside - 1)
  func aheadAt(_ distance: Double) -> Double {
    distance >= high ? highest : ahead.at(distance)
  }
  var rise = aheadAt(low + run) - lowest
  for point in points[inside...] {
    if point.distance > high - run { break }
    if point.distance > low {
      rise = maximumNumber(rise, aheadAt(point.distance + run) - point.elevation)
    }
  }

  // The runs that end at each sample and at the stretch's own end.
  var behind = CurveCursor(points: points, startIndex: inside - 1)
  for point in points[inside...] {
    if point.distance >= high { break }
    if point.distance >= low + run {
      rise = maximumNumber(rise, point.elevation - behind.at(point.distance - run))
    }
  }
  rise = maximumNumber(rise, highest - behind.at(high - run))

  return maximumNumber(0, convertSlope(rise / run, from: .ratio, to: .degrees))
}

/// CurveCursor reads the curve of a series' samples at distances asked in ascending order, in one
/// pass over the samples: it only moves forward, from the index it starts at. A distance before
/// the sample it stands on reads that sample's altitude.
private struct CurveCursor {
  let points: [ElevationPoint]
  var index: Int

  init(points: [ElevationPoint], startIndex: Int) {
    self.points = points
    self.index = max(0, startIndex)
  }

  mutating func at(_ distance: Double) -> Double {
    while index + 1 < points.count, points[index + 1].distance <= distance {
      index += 1
    }
    guard index < points.count else { return 0 }
    let before = points[index]
    guard index + 1 < points.count, distance > before.distance else { return before.elevation }
    let after = points[index + 1]
    return before.elevation + (after.elevation - before.elevation) * (distance - before.distance)
      / (after.distance - before.distance)
  }
}
