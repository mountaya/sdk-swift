/// normalizeBoundingBox writes a box, `[west, south, east, north]` in degrees, in canonical form.
///
/// Each axis is ordered low to high, so a west edge greater than the east one is a box drawn from
/// its east corner and never one crossing the antimeridian; the west edge is brought within
/// [-180, 180] by whole turns with the east edge following it, past 180 where the box crosses the
/// antimeridian, as `boundsOf(_:)` frames one; a box a turn or more wide, or with a longitude at an
/// infinity on its west, is the whole world, `[-180, south, 180, north]`; and each latitude is held
/// within `webMercatorMaxLatitude`. A box the API answers with its west edge greater than its east
/// one crosses the antimeridian, as RFC 7946 writes it, and is read as
/// `[west, south, east + 360, north]` where it is received, before it is handed here.
///
/// Nothing is refused. A longitude that is `NaN`, or both at one infinity, answers `NaN` for both
/// longitudes, a latitude that is `NaN` answers itself, and a box that is not four numbers, an
/// RFC 7946 box of six included, answers four `NaN`s.
public func normalizeBoundingBox(_ bounds: [Double]) -> [Double] {
  guard bounds.count == 4 else { return [.nan, .nan, .nan, .nan] }
  let longitudes = canonicalLongitudes(
    west: minimumNumber(bounds[0], bounds[2]), east: maximumNumber(bounds[0], bounds[2]))
  let limit = -webMercatorMaxLatitude...webMercatorMaxLatitude
  return [
    longitudes[0],
    clampNumber(minimumNumber(bounds[1], bounds[3]), to: limit),
    longitudes[1],
    clampNumber(maximumNumber(bounds[1], bounds[3]), to: limit),
  ]
}
