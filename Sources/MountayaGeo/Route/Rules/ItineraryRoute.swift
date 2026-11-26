import MountayaClient

/// itineraryRoute is the one route a fly-through follows over an itinerary's segments, as the API
/// answers them, or over the one segment `segmentId` names; nil names none, and flies them all.
///
/// Every line a segment holds is laid end to end, the segments in chain order, by their
/// `position`, two at one position in the order they are listed, and their lines in the order
/// their `geojson` writes them: a LineString is one line and each line of a MultiLineString is
/// one, a GeometryCollection holds the lines of what it holds, and a MultiPoint, a directions
/// segment's vias, is no line and is left out, as is a segment with no geometry. A vertex that
/// names no place, short of a longitude or a latitude or with either not finite, is left out with
/// its elevation, and a line none of whose vertices names a place opens no line.
///
/// The route's line keeps each vertex's longitude and latitude. The first vertex of each line
/// after the first is a jump: the camera flies the leg that reaches it, while the itinerary's
/// distance charges nothing for it. The elevations are the vertices' third values, stated only
/// where every vertex kept carries a finite one. The answer is nil where fewer than two vertices
/// name a place: an unknown segment, segments holding no line, or a single vertex, since a flight
/// needs a direction.
public func itineraryRoute(
  _ segments: [RestSchema.ItinerarySegment], segmentId: String? = nil
) -> RouteGeometry? {
  let flown: [RestSchema.ItinerarySegment]
  if let segmentId {
    flown = segments.first { $0.id == segmentId }.map { [$0] } ?? []
  } else {
    // The chain order; a sort that keeps the listed order of two segments at one position.
    flown = segments.enumerated()
      .sorted { ($0.element.position, $0.offset) < ($1.element.position, $1.offset) }
      .map(\.element)
  }
  var line: [[Double]] = []
  var elevations: [Double] = []
  var jumps: [Int] = []
  var everyVertexHasElevation = true
  for segment in flown {
    for vertices in linesOf(segment.geojson) {
      var opensLine = true
      for vertex in vertices where namesPlace(vertex) {
        // The first vertex a line contributes is where the flight lands from the line before.
        if opensLine, !line.isEmpty { jumps.append(line.count) }
        opensLine = false
        line.append([vertex[0], vertex[1]])
        if vertex.count > 2, vertex[2].isFinite {
          elevations.append(vertex[2])
        } else {
          everyVertexHasElevation = false
        }
      }
    }
  }
  guard line.count >= 2 else { return nil }
  return RouteGeometry(
    line: line, elevations: everyVertexHasElevation ? elevations : [], jumps: jumps)
}
