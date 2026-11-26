import MountayaClient

/// linesOf is the lines a geometry holds, in the order it writes them, each a list of positions: a
/// LineString is one line and each line of a MultiLineString is one, a GeometryCollection holds
/// the lines of what it holds at any depth, and a point, a MultiPoint (a directions segment's
/// vias) or a polygon is no line. No geometry holds none.
///
/// It is the one statement of what a line of an itinerary is, which every walk of one reads.
func linesOf(_ geometry: GeoJSONGeometry?) -> [[[Double]]] {
  switch geometry {
  case nil: return []
  case .lineString(let line)?: return [line.coordinates]
  case .multiLineString(let lines)?: return lines.coordinates
  case .geometryCollection(let collection)?: return collection.geometries.flatMap(linesOf)
  case .point?, .multiPoint?, .polygon?, .multiPolygon?: return []
  }
}
