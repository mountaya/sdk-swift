import MountayaClient

/// boundsOf is the box `[west, south, east, north]`, in degrees, around every position of some
/// geometries, a collection of any depth flattened first, so a directions segment bounds its vias
/// as well as its line; or nil where no position names a place.
///
/// A longitude is read in two frames, as written and with the western hemisphere turned a turn
/// east, and the box is the narrower of the two: a set as written more than half a turn wide that
/// the turned frame reads narrower, one straddling the antimeridian or a shape cut in two there, is
/// framed across it, its west edge within [-180, 180] and its east edge past 180, as
/// `normalizeBoundingBox(_:)` keeps a box. Positions alone cannot tell such a set from one drawn
/// wider than half the world across the prime meridian, which reads the narrow way too. A set
/// whose every position lies on the antimeridian, written as both 180 and -180, keeps its written
/// width. Every other set keeps its longitudes as written.
///
/// A position that names no place, short of a longitude or a latitude or with either not finite,
/// bounds nothing, and an altitude is ignored. An edge is the first extreme value met, so of 0 and
/// -0 it is the one written first.
public func boundsOf(_ geometries: [GeoJSONGeometry]) -> [Double]? {
  var extent = Extent()
  for geometry in geometries {
    extent.cover(geometry)
  }
  return extent.box()
}

/// Extent is the extremes of the positions met so far, the longitudes in both frames.
private struct Extent {
  var west = Double.infinity
  var east = -Double.infinity
  var turnedWest = Double.infinity
  var turnedEast = -Double.infinity
  var south = Double.infinity
  var north = -Double.infinity

  mutating func cover(_ geometry: GeoJSONGeometry) {
    switch geometry {
    case .point(let point):
      visit(point.coordinates)
    case .multiPoint(let points):
      points.coordinates.forEach { visit($0) }
    case .lineString(let line):
      line.coordinates.forEach { visit($0) }
    case .multiLineString(let lines):
      lines.coordinates.forEach { $0.forEach { visit($0) } }
    case .polygon(let polygon):
      polygon.coordinates.forEach { $0.forEach { visit($0) } }
    case .multiPolygon(let polygons):
      polygons.coordinates.forEach { $0.forEach { $0.forEach { visit($0) } } }
    case .geometryCollection(let collection):
      collection.geometries.forEach { cover($0) }
    }
  }

  private mutating func visit(_ position: [Double]) {
    guard namesPlace(position) else { return }
    let longitude = position[0]
    let latitude = position[1]
    // The western hemisphere a turn east, where a set straddling the antimeridian is one short run.
    let turned = longitude < 0 ? longitude + degreesPerTurn : longitude
    if longitude < west { west = longitude }
    if longitude > east { east = longitude }
    if turned < turnedWest { turnedWest = turned }
    if turned > turnedEast { turnedEast = turned }
    if latitude < south { south = latitude }
    if latitude > north { north = latitude }
  }

  func box() -> [Double]? {
    guard south != .infinity else { return nil }
    let writtenSpan = east - west
    let turnedSpan = turnedEast - turnedWest
    // The turned frame is asked only of a set more than half a turn wide as written, so a turn's
    // rounding (a tiny negative longitude plus 360 is 360) never reads a small set the long way
    // round. A turned frame of no width on the antimeridian is a set lying wholly on it, written
    // from both sides, and it keeps its written width.
    let onAntimeridian = turnedSpan == 0 && turnedWest == longitudeLimit
    if writtenSpan > longitudeLimit, !onAntimeridian, turnedSpan < writtenSpan {
      let shift = turnedWest > longitudeLimit ? degreesPerTurn : 0
      return [turnedWest - shift, south, turnedEast - shift, north]
    }
    return [west, south, east, north]
  }
}
