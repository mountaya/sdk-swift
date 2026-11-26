/// longitudeLimit is the longitude of the antimeridian, half a turn from the prime meridian.
let longitudeLimit: Double = 180

/// wrapLongitude brings a longitude, in degrees, into [-180, 180) by whole turns, so the
/// antimeridian is written -180 and 190 is -170. A longitude that is not finite names no meridian
/// and wraps to `NaN`.
///
/// It is the remainder of the longitude past -180 by a turn, taken twice so a negative one lands
/// in the turn too, each the truncated remainder, never the IEEE one `remainder(dividingBy:)`
/// takes. The arithmetic costs a longitude already in the range its last digits;
/// `wrapLongitudePastRange(_:)` keeps those.
public func wrapLongitude(_ longitude: Double) -> Double {
  let pastWestEdge = (longitude + longitudeLimit).truncatingRemainder(dividingBy: degreesPerTurn)
  return (pastWestEdge + degreesPerTurn).truncatingRemainder(dividingBy: degreesPerTurn)
    - longitudeLimit
}
