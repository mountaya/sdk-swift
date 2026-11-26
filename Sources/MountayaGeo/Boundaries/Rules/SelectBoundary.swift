import MountayaClient

/// selectBoundary is the boundary a map locks its camera to from its center, `[longitude,
/// latitude]`: of the boundaries, in the order the organization lists them, the first whose box
/// holds the center, else the first, and nil where there is none, which a map reads as no lock. A
/// boundary is the REST API's own, a `name` and a `bbox` written `[west, south, east, north]` in
/// degrees, handed over as it arrived.
///
/// A box holds the center when the center's latitude lies between its south and north edges and
/// its meridian lies east of the west edge by no more than the box is wide, the longitudes read as
/// angles however many turns apart they are written, so a box across the antimeridian holds a
/// center written on either side, and a box a turn or more wide holds every meridian. A center on
/// an edge is inside.
///
/// A center that names no place, short of a longitude or a latitude or with either not finite, is
/// held by no box. A box that is not four numbers holds nothing, and neither does one whose east
/// edge lies west of its west edge or whose north edge lies south of its south edge, since the
/// wire writes the minimum corner first.
public func selectBoundary(_ boundaries: [RestSchema.Boundaries], center: [Double])
  -> RestSchema.Boundaries?
{
  guard let first = boundaries.first else { return nil }
  guard namesPlace(center) else { return first }
  return boundaries.first { holds($0.bbox, longitude: center[0], latitude: center[1]) } ?? first
}

/// holds tells whether a box `[west, south, east, north]` holds a center.
private func holds(_ box: [Double], longitude: Double, latitude: Double) -> Bool {
  guard box.count == 4 else { return false }
  let (west, south, east, north) = (box[0], box[1], box[2], box[3])
  guard latitude >= south, latitude <= north else { return false }
  if longitude >= west, longitude <= east { return true }
  // How far east of the west edge the center's meridian lies, within [0, 360): inside the box
  // when that is no farther than the box is wide.
  let eastOfWestEdge = wrapLongitude(longitude - west - longitudeLimit) + longitudeLimit
  return eastOfWestEdge <= east - west
}
