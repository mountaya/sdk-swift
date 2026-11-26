import Foundation

/// bearingDegrees is the initial great-circle bearing from one position to another,
/// `[longitude, latitude]` in degrees: the compass heading to set out on, within [0, 360), 0 north
/// and 90 east.
///
/// The longitudes are read as angles, the short way round, so a position written 180 and one
/// written -180 are one place. Two positions that are one place have no heading and answer 0. A
/// position that names no place, short of a longitude or a latitude or with either not finite,
/// answers `NaN`. An altitude is ignored.
public func bearingDegrees(from: [Double], to: [Double]) -> Double {
  guard namesPlace(from), namesPlace(to) else { return .nan }
  let longitudeSpan = longitudeDelta(from: from[0], to: to[0]) * radiansPerDegree
  if longitudeSpan == 0, from[1] == to[1] { return 0 }
  let latitudeFrom = from[1] * radiansPerDegree
  let latitudeTo = to[1] * radiansPerDegree
  let east = sin(longitudeSpan) * cos(latitudeTo)
  let north =
    cos(latitudeFrom) * sin(latitudeTo) - sin(latitudeFrom) * cos(latitudeTo) * cos(longitudeSpan)
  return compassBearing(atan2(east, north) * degreesPerRadian)
}

/// compassBearing writes an angle from north, within [-180, 180] as `atan2` answers one, as a
/// compass bearing within [0, 360): one under zero is brought into the turn, a negative zero reads
/// as zero, and one so close under zero that a turn added to it rounds to a whole turn is north.
/// `NaN` stays `NaN`.
func compassBearing(_ degrees: Double) -> Double {
  let bearing = degrees < 0 ? degrees + degreesPerTurn : degrees + 0
  return bearing >= degreesPerTurn ? 0 : bearing
}
