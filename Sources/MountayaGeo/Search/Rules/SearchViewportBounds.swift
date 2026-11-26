import Foundation

/// searchBoundsMaxSpanDegrees is the widest span, in degrees, a viewport-restricted search asks
/// about on either axis.
public let searchBoundsMaxSpanDegrees = 90.0

/// searchBoundsCosineFloor is the least the cosine of the centre's latitude narrows a search's
/// latitude span by, so a box near a pole still spans a twentieth of its longitude span rather than
/// nothing.
public let searchBoundsCosineFloor = 0.05

/// The latitude of a pole.
private let latitudeLimit = 90.0

/// searchViewportBounds is the box `[west, south, east, north]` a viewport-restricted search sends
/// for a camera at `center`, `[longitude, latitude]`, and `zoom`: the centre's longitude wrapped
/// into [-180, 180) and its latitude held within [-90, 90]; a longitude span of `360 / 2^zoom`
/// degrees, at most `searchBoundsMaxSpanDegrees`; a latitude span of that times the cosine of the
/// centre's latitude, the cosine at least `searchBoundsCosineFloor`; and each edge half its span
/// from the centre, held within [-180, 180] and [-90, 90], so the box never crosses the
/// antimeridian or a pole. At zoom 12 over the Mont Blanc valley it spans 0.088 degrees of
/// longitude.
///
/// Four `NaN`s for a centre that names no place, and `NaN` wherever `zoom` is no number: the holds
/// keep a `NaN` rather than read it as an edge.
public func searchViewportBounds(center: [Double], zoom: Double) -> [Double] {
  guard namesPlace(center) else { return [.nan, .nan, .nan, .nan] }
  let longitude = wrapLongitude(center[0])
  let latitude = clampNumber(center[1], to: -latitudeLimit...latitudeLimit)
  let span = minimumNumber(degreesPerTurn / pow(2, zoom), searchBoundsMaxSpanDegrees)
  let latitudeSpan =
    span * maximumNumber(searchBoundsCosineFloor, cos(latitude * radiansPerDegree))
  return [
    clampNumber(longitude - span / 2, to: -longitudeLimit...longitudeLimit),
    clampNumber(latitude - latitudeSpan / 2, to: -latitudeLimit...latitudeLimit),
    clampNumber(longitude + span / 2, to: -longitudeLimit...longitudeLimit),
    clampNumber(latitude + latitudeSpan / 2, to: -latitudeLimit...latitudeLimit),
  ]
}
