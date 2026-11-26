/// A difference this near zero is a floating-point tail of two large accumulations, and is zero.
private let accumulationTail = 1e-6

/// rangeTotals states the stretch of a series between the distances `from` and `to`, in meters from
/// the itinerary's start, read off one cumulative scan of the whole series. A range given backwards
/// is read in order.
///
/// Its ascent and descent are differences of the series' cumulative readings at its two ends, each
/// reading interpolated linearly between the samples either side of it, so the stretches of an
/// itinerary sum to its totals exactly and the noise threshold never restarts at a boundary. Its
/// distance is the stretch's own length, and its altitude band and steepest grade are its own, read
/// on the curve between samples, so a stretch shorter than the gap between two samples still states
/// a band and a grade. Over the whole itinerary it answers what `profileTotals(_:)` answers.
///
/// A stretch the samples do not reach states no band and no grade, and a series with no sample
/// states the stretch's length alone.
public func rangeTotals(_ series: ElevationSeries, from: Double, to: Double) -> ProfileTotals {
  let points = series.points
  let start = minimumNumber(from, to)
  let end = maximumNumber(from, to)
  guard !points.isEmpty else {
    return ProfileTotals(
      distance: end - start, ascent: nil, descent: nil, elevationMin: nil, elevationMax: nil,
      gradeMax: nil)
  }
  let cumulative = cumulativeElevation(points)
  let ascent =
    readCumulative(points, totals: cumulative.ascent, at: end)
    - readCumulative(points, totals: cumulative.ascent, at: start)
  let descent =
    readCumulative(points, totals: cumulative.descent, at: end)
    - readCumulative(points, totals: cumulative.descent, at: start)
  let band = altitudeBand(points, from: start, to: end)
  return ProfileTotals(
    distance: end - start,
    ascent: nonNegative(ascent),
    descent: nonNegative(descent),
    elevationMin: band?.lowest,
    elevationMax: band?.highest,
    gradeMax: steepestGrade(points, from: start, to: end)
  )
}

/// A difference of two readings, zero where it is a floating-point tail of zero and never under it.
private func nonNegative(_ value: Double) -> Double {
  abs(value) < accumulationTail ? 0 : maximumNumber(0, value)
}

/// Reads the cumulative totals of a series' samples at `distance`, linearly between the two samples
/// either side of it rather than snapped to the nearer, so a boundary a few meters from a sample
/// never gives that sample's whole step to one side. Before the first sample it reads the first,
/// past the last the last.
private func readCumulative(
  _ points: [ElevationPoint], totals: [Double], at distance: Double
) -> Double {
  guard let first = points.first, let last = points.last, let firstTotal = totals.first,
    let lastTotal = totals.last
  else { return 0 }
  if distance <= first.distance { return firstTotal }
  if distance >= last.distance { return lastTotal }
  let after = firstIndexAtOrPast(points, distance: distance)
  if after <= 0 || after >= points.count { return lastTotal }
  let start = points[after - 1]
  let end = points[after]
  let low = totals[after - 1]
  let high = totals[after]
  let run = end.distance - start.distance
  return run <= 0 ? high : low + (high - low) * (distance - start.distance) / run
}
