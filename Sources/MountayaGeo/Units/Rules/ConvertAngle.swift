/// radiansPerDegree is the radians in a degree, pi over 180, the `degreesToRadians`
/// `geo/geodesy.json` declares.
let radiansPerDegree: Double = .pi / 180

/// degreesPerRadian is the degrees in a radian, 180 over pi, the `degreesPerRadian`
/// `geo/units-convert.json` declares.
let degreesPerRadian: Double = 180 / .pi

/// degreesPerTurn is the degrees in a turn, the `degreesPerTurn` `geo/terrain-slope-aspect.json`
/// declares.
let degreesPerTurn: Double = 360

/// convertAngle converts a value from one angle unit to the other through pi over 180, always as
/// a product by the precomputed factor, never a division. A value in its own unit is returned as
/// it is, and nothing is reduced to one turn: 720 degrees is four pi.
public func convertAngle(_ value: Double, from: AngleUnit, to: AngleUnit) -> Double {
  if from == to { return value }
  return to == .radian ? value * radiansPerDegree : value * degreesPerRadian
}
