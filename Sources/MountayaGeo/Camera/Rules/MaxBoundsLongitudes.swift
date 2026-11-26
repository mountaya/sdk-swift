/// worldLockHalfSpanDegrees is half the width, in degrees, of the pan lock written for the whole
/// world, a hair under half a turn, the `worldLockHalfSpanDegrees`
/// `geo/max-bounds-longitudes.json` declares.
let worldLockHalfSpanDegrees: Double = longitudeLimit - 1e-10

/// maxBoundsLongitudes writes a pan lock's west and east edges, in degrees, as `[west, east]`, the
/// edges a renderer's pan lock is handed.
///
/// A lock narrower than a turn keeps the width it is written with: its west edge is brought within
/// [-180, 180] by whole turns and its east edge follows, past 180 where the lock crosses the
/// antimeridian, as a box is written. Edges written east first are answered in that order, never
/// reordered, since a renderer reads such a pair as a lock across the antimeridian.
///
/// A lock a turn or more wide covers every longitude, and is written as the whole world a hair
/// under a turn wide, `180 - 1e-10` degrees either side of the lock's centre, the centre brought
/// within [-180, 180] first so the hair survives rounding however many turns out the lock is
/// written. A renderer that wraps both edges into one world before it measures a lock finds the
/// edges of one exactly a turn wide on one meridian, and measures no width. A west edge at the
/// western infinity or an east edge at the eastern one reaches as far as a lock can, and is the
/// whole world centred on the prime meridian.
///
/// An edge that is `NaN`, both edges at one infinity, and edges written east first with one at an
/// infinity place the lock nowhere, and both edges answer `NaN`.
public func maxBoundsLongitudes(west: Double, east: Double) -> [Double] {
  guard east - west >= degreesPerTurn else { return canonicalLongitudes(west: west, east: east) }
  let middle = (west + east) / 2
  let centre = middle.isFinite ? canonicalLongitudes(west: middle, east: middle)[0] : 0
  return canonicalLongitudes(
    west: centre - worldLockHalfSpanDegrees, east: centre + worldLockHalfSpanDegrees)
}
