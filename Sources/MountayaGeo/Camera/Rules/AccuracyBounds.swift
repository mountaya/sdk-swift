import Foundation

/// locateMaxZoom is the highest zoom a device fix is framed at, the `maxZoom`
/// `geo/accuracy-bounds.json` and `map/camera-locate.json` declare: a fix precise to a few meters
/// frames a street rather than a doorway.
public let locateMaxZoom: Double = 16

/// accuracyBounds is the box a device fix is framed by (`geo.camera.accuracy-bounds`): the square
/// around `position`, `[longitude, latitude]`, that its accuracy radius spans, `radiusMeters` how
/// far from it the device may stand.
///
/// The radius is an arc of the Web Mercator sphere's circumference,
/// `webMercatorCircumferenceMeters`, the sphere the camera frames the box on, so the box spans 360
/// times the radius over the circumference in degrees of latitude either side of the fix, and that
/// over the cosine of the latitude in degrees of longitude, where a degree of longitude is shorter.
/// A camera framing it fits it at `locateMaxZoom` at most. A fix of no accuracy is the box of its
/// position alone, and a box across the antimeridian keeps its east edge past 180, as every box of
/// the geo layer does.
///
/// Nothing is refused: a position that names no place, or a radius that is no number, answers the
/// box its numbers give, `NaN` where they hold one.
public func accuracyBounds(_ position: [Double], radiusMeters: Double) -> [Double] {
  let longitude = position.first ?? .nan
  let latitude = position.count > 1 ? position[1] : .nan
  let latitudeSpan = radiusMeters / metersPerDegreeWebMercator
  let longitudeSpan = latitudeSpan / cos(latitude * radiansPerDegree)
  return [
    longitude - longitudeSpan, latitude - latitudeSpan,
    longitude + longitudeSpan, latitude + latitudeSpan,
  ]
}
