import Foundation

/// earthRadiusMeters is the radius of the mean Earth sphere every distance of the geo layer is
/// measured on, the `earthRadiusMeters` `geo/geodesy.json` declares: the IUGG mean radius, never a
/// platform's ellipsoid.
public let earthRadiusMeters: Double = 6_371_000

/// metersPerDegreeMeanSphere is the ground length of one degree of arc on the sphere
/// `earthRadiusMeters` describes, about 111,194.93 m: a degree of latitude anywhere, and a degree
/// of longitude at the equator. It is the radius times pi over 180, and the degree every planar
/// span on the ground is measured in.
public let metersPerDegreeMeanSphere: Double = earthRadiusMeters * (.pi / 180)

/// haversineMeters is the great-circle distance between two positions, `[longitude, latitude]` in
/// degrees, in meters on the sphere `earthRadiusMeters` describes. Every other distance of the geo
/// layer is this function or a sum of it.
///
/// Two positions that name places measure a finite distance, from zero to half the
/// circumference, across the antimeridian the short way round. A position that names no place,
/// short of a longitude or a latitude or with either not finite, measures `NaN`. An altitude is
/// no part of the distance.
public func haversineMeters(from: [Double], to: [Double]) -> Double {
  guard namesPlace(from), namesPlace(to) else { return .nan }
  let latitudeFrom = from[1] * radiansPerDegree
  let latitudeTo = to[1] * radiansPerDegree
  let sinLatitude = sin((to[1] - from[1]) * radiansPerDegree / 2)
  let sinLongitude = sin((to[0] - from[0]) * radiansPerDegree / 2)
  let term =
    sinLatitude * sinLatitude + cos(latitudeFrom) * cos(latitudeTo) * sinLongitude * sinLongitude
  // The term lies in 0 to 1 for any two angles, and rounding can leave it a hair outside: past
  // one for two antipodes, under zero for one place written on both sides of a pole. The root
  // and the arcsine have no answer out there.
  return 2 * earthRadiusMeters * asin(sqrt(clampNumber(term, to: 0...1)))
}
