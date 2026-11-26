import Foundation

/// slopeAspectFromNeighbours answers the slope and the aspect of the ground at a point at a
/// latitude, in degrees, from its neighbours, the elevations `spacingDegrees` away to its north,
/// south, east and west: a central-difference gradient measured on the ground in the degree of the
/// mean sphere, the east-west span shrunk by the cosine of the latitude.
///
/// The slope is the gradient's magnitude as an angle in degrees. The aspect is the compass bearing
/// of the descent within [0, 360), 0 north and 90 east, and nil where the four neighbours leave no
/// gradient. Nothing is refused: a neighbour, a latitude or a spacing that is not finite answers
/// what the arithmetic answers, `NaN` for both where a neighbour is `NaN`, and a spacing of zero
/// `NaN` for both even on flat ground.
public func slopeAspectFromNeighbours(
  _ neighbours: TerrainNeighbours, latitude: Double, spacingDegrees: Double
) -> SlopeAspect {
  let metersNorth = spacingDegrees * metersPerDegreeMeanSphere
  let metersEast = metersNorth * cos(latitude * radiansPerDegree)
  // The rise per meter going east, and going north.
  let riseEast = (neighbours.east - neighbours.west) / (2 * metersEast)
  let riseNorth = (neighbours.north - neighbours.south) / (2 * metersNorth)
  let slope = convertSlope(hypot(riseEast, riseNorth), from: .ratio, to: .degrees)

  // No gradient is flat ground, which falls in no direction. Read through atan2 it would answer a
  // bearing, since two zeros of either sign have an angle there.
  if riseEast == 0, riseNorth == 0 { return SlopeAspect(slope: slope, aspect: nil) }

  // atan2(east, north) of the descent is a compass bearing: 0 north, 90 east, clockwise.
  let bearing = compassBearing(atan2(-riseEast, -riseNorth) * degreesPerRadian)
  return SlopeAspect(slope: slope, aspect: bearing)
}
