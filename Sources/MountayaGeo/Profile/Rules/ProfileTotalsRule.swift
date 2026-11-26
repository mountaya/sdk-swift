/// elevationNoiseThresholdMeters is the rise or fall a stretch must reach before it counts as
/// ascent or descent, the `elevationNoiseThresholdMeters` `geo/elevation-totals.json` declares: a
/// sample this far above or below the last one counted is counted, and any nearer is noise. Summed
/// straight from sampled terrain, a flat road reports hundreds of meters of climb.
public let elevationNoiseThresholdMeters: Double = 5

/// gradeWindowMeters is the run a maximum grade is measured over, the `gradeWindowMeters`
/// `geo/elevation-totals.json` declares, so the figure means the steepest hundred meters rather
/// than the ratio of two noisy altitudes a few meters apart.
public let gradeWindowMeters: Double = 100

/// profileTotals derives an itinerary's figures from its elevation series: its length, the whole
/// series' total distance; its ascent and descent, accumulated through the
/// `elevationNoiseThresholdMeters` hysteresis; its altitude band, the series' own; and its steepest
/// ascending `gradeWindowMeters`, in degrees and never under 0.
///
/// Treat the ascent and the descent as estimates: the hysteresis removes the double counting raw
/// terrain samples produce and clips up to the threshold off each genuine climb, so an itinerary
/// holding its server's metrics states those. A series with no sample states its length alone.
///
/// Its file is `ProfileTotalsRule.swift`, since Swift refuses two files of one name in a target and
/// `ProfileTotals.swift` is the answer type's.
public func profileTotals(_ series: ElevationSeries) -> ProfileTotals {
  let points = series.points
  let cumulative = cumulativeElevation(points)
  guard let ascent = cumulative.ascent.last, let descent = cumulative.descent.last else {
    return ProfileTotals(
      distance: series.totalDistance, ascent: nil, descent: nil, elevationMin: nil,
      elevationMax: nil, gradeMax: nil)
  }
  return ProfileTotals(
    distance: series.totalDistance,
    ascent: ascent,
    descent: descent,
    elevationMin: series.minElevation,
    elevationMax: series.maxElevation,
    gradeMax: steepestGrade(points, from: -.infinity, to: .infinity)
  )
}
