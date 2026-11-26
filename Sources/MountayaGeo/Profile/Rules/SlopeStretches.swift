/// slopeBuckets is the ramp a profile's own steepness is painted from where its caller names no
/// other, the `buckets` `geo/profile-slope-stretches.json` declares: steep descent, descent, flat,
/// ascent and steep ascent at -10, -3, 3 and 10 degrees, the angles a walker feels the difference
/// at, coloured green through orange in the direction difficulty runs.
public let slopeBuckets = [
  SlopeBucket(from: -.infinity, key: "steepDescent", color: "#e8590c"),
  SlopeBucket(from: -10, key: "descent", color: "#f59f00"),
  SlopeBucket(from: -3, key: "flat", color: "#2f9e44"),
  SlopeBucket(from: 3, key: "ascent", color: "#f59f00"),
  SlopeBucket(from: 10, key: "steepAscent", color: "#e8590c"),
]

/// slopeStretches is an itinerary's own steepness as the stretches its profile's curve is painted
/// in, in distance order (`geo.profile.slope-stretches`), each labelled with its bucket's key.
///
/// Each sample after the first ends a stretch from the sample before it, and the first reads the
/// stretch it starts. A stretch at least `gradeWindowMeters` long reads as its own slope, its rise
/// over its run, since a thinned long itinerary carries a sample every few hundred meters and a
/// window centred on it would straddle the stretches either side; a shorter one reads
/// `gradeAt(_:distance:)` at its sample, since two noisy samples a few meters apart are no cliff.
/// The slope falls in the last bucket whose `from` it reaches, the first where it reaches none.
/// Neighbours of one bucket merge into one stretch, each stretch starts where the one before it
/// ends, and one of no length is left out. A series of fewer than two samples, or a ramp of no
/// bucket, has none.
public func slopeStretches(_ points: [ElevationPoint], buckets: [SlopeBucket] = slopeBuckets)
  -> [ProfileClass]
{
  guard points.count >= 2, let lowest = buckets.first else { return [] }
  var stretches: [ProfileClass] = []
  for (index, point) in points.enumerated() {
    guard let grade = stretchGrade(points, index: index) else { continue }
    let bucket = buckets.last { grade >= $0.from } ?? lowest
    if let open = stretches.last, sameText(open.label, bucket.key) {
      stretches[stretches.count - 1].to = point.distance
      continue
    }
    stretches.append(
      ProfileClass(
        from: stretches.last?.to ?? point.distance, to: point.distance, color: bucket.color,
        label: bucket.key))
  }
  return stretches.filter { $0.to > $0.from }
}

/// The slope of the stretch that ends at the sample at `index`, in degrees: its own where the sample
/// before it stands at least the grade window back, else the grade at the sample. The first sample
/// reads the stretch it starts.
private func stretchGrade(_ points: [ElevationPoint], index: Int) -> Double? {
  let start = points[max(0, index - 1)]
  let end = points[max(1, index)]
  let run = end.distance - start.distance
  if run >= gradeWindowMeters {
    return convertSlope((end.elevation - start.elevation) / run, from: .ratio, to: .degrees)
  }
  return gradeAt(points, distance: points[index].distance)
}
