/// aspectSectorDegrees is the arc of the compass each `AspectCardinal` names, centred on its own
/// heading.
let aspectSectorDegrees: Double = 45

/// aspectCardinal answers the compass direction an aspect of `degrees` faces
/// (`geo.terrain.aspect-cardinal`): the bearing, 0 north and 90 east, folded into [0, 360) by whole
/// turns, names the direction whose 45 degrees, centred on its own heading, hold it, north from
/// 337.5 to 22.5. A bearing on the edge between two sectors names the one clockwise of it, so 22.5
/// is north-east and 337.5 north.
///
/// nil for a bearing that is no finite number, which faces no direction.
public func aspectCardinal(_ degrees: Double) -> AspectCardinal? {
  guard degrees.isFinite else { return nil }
  let folded = compassBearing(degrees.truncatingRemainder(dividingBy: degreesPerTurn))
  let sector = Int(((folded + aspectSectorDegrees / 2) / aspectSectorDegrees).rounded(.down))
  return AspectCardinal.allCases[sector % AspectCardinal.allCases.count]
}
