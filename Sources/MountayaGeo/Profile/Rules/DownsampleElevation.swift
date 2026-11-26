/// downsampleElevation is a series' samples thinned to `maxPoints` at most by a uniform stride,
/// each renumbered by its place in the answer. The first and the last are always kept: slot `k` of
/// the others keeps the sample nearest `k × (count − 1) / (maxPoints − 1)`, the later of two where
/// the slot stands halfway between them. The slot is computed in whole numbers, so a half is a
/// half: a stride in floating point reads 249 × 503 / 498, which is 251.5, as 251.49999999999997.
///
/// A ceiling under two, or a series already within it, keeps every sample.
func downsampleElevation(_ points: [ElevationPoint], maxPoints: Int) -> [ElevationPoint] {
  if maxPoints < 2 || points.count <= maxPoints {
    return points.enumerated().map { renumbered($0.element, as: $0.offset) }
  }
  let last = points.count - 1
  let slots = maxPoints - 1
  var kept: [ElevationPoint] = []
  kept.reserveCapacity(maxPoints)
  for slot in 0..<slots {
    // The nearest whole index to slot × last / slots, a half up:
    // floor((2 × slot × last + slots) / (2 × slots)).
    let index = (2 * slot * last + slots) / (2 * slots)
    kept.append(renumbered(points[index], as: kept.count))
  }
  kept.append(renumbered(points[last], as: kept.count))
  return kept
}

/// The sample numbered `index`.
private func renumbered(_ point: ElevationPoint, as index: Int) -> ElevationPoint {
  var numbered = point
  numbered.index = index
  return numbered
}
