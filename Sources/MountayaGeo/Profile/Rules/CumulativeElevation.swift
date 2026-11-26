/// CumulativeElevation is the meters climbed and the meters dropped from an itinerary's start to
/// each sample of its series, index for index with the series' points.
struct CumulativeElevation: Sendable, Hashable {
  let ascent: [Double]
  let descent: [Double]
}

/// cumulativeElevation runs the `elevationNoiseThresholdMeters` hysteresis once over a series'
/// samples and records it at every sample. A reference altitude is carried forward: a sample at
/// least the threshold above it counts the rise and becomes the reference, one at least the
/// threshold below counts the fall, and any other leaves both, so a jitter of a few meters is never
/// counted.
///
/// Every figure of a stretch is a difference of these readings, never the hysteresis run over the
/// stretch alone, which would reset the reference at each boundary and clip the threshold off each
/// end: the stretches of an itinerary then sum to its totals exactly.
func cumulativeElevation(_ points: [ElevationPoint]) -> CumulativeElevation {
  guard let first = points.first else { return CumulativeElevation(ascent: [], descent: []) }
  var ascent: [Double] = []
  var descent: [Double] = []
  ascent.reserveCapacity(points.count)
  descent.reserveCapacity(points.count)
  var climbed: Double = 0
  var dropped: Double = 0
  var reference = first.elevation
  for point in points {
    let delta = point.elevation - reference
    if delta >= elevationNoiseThresholdMeters {
      climbed += delta
      reference = point.elevation
    } else if delta <= -elevationNoiseThresholdMeters {
      dropped -= delta
      reference = point.elevation
    }
    ascent.append(climbed)
    descent.append(dropped)
  }
  return CumulativeElevation(ascent: ascent, descent: descent)
}
