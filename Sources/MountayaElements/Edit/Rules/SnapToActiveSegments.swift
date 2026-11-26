/// snapThresholdPx is the radius of an edit's magnet, in the screen's density-independent pixels,
/// iOS's points: a point the pointer holds within it of a line is placed on the line
/// (`map.edit.snap`).
let snapThresholdPx: Double = 40

/// snapToActiveSegments places a point the pointer holds at `position`: on the nearest point of
/// any edge of `segments`, the lines of the itinerary being edited, where that point lies within
/// `thresholdPx` of the pointer, the threshold itself included, and under the pointer otherwise
/// (`map.edit.snap`).
///
/// Every distance is measured on the screen, through `projection`, and the nearest point of an
/// edge is held to the edge's ends, so beyond an end the end is nearest. The edges are read in
/// order, line by line, and of two at one distance the first is kept. A line of one position has
/// no edge, and no line at all leaves the pointer where it is without reading the projection. A
/// position missing a coordinate reads it as 0, and a distance that is no number, from a position
/// that names no place, is never the nearest, so such a pointer is left where it is. It runs on
/// the main actor, where a renderer's projection reads its map.
@MainActor
func snapToActiveSegments(
  _ position: [Double],
  segments: [[[Double]]],
  projection: ScreenProjection,
  thresholdPx: Double = snapThresholdPx
) -> EditSnap {
  guard !segments.isEmpty else { return EditSnap(position: position, isSnapped: false) }
  let pointer = pixel(projection.point(lngLat(position)))
  var nearest: (x: Double, y: Double)?
  var nearestSquared = Double.infinity
  for line in segments where line.count > 1 {
    for index in line.indices.dropFirst() {
      let start = pixel(projection.point(lngLat(line[index - 1])))
      let end = pixel(projection.point(lngLat(line[index])))
      let foot = footOnEdge(pointer, from: start, to: end)
      let squared = squaredDistance(pointer, foot)
      if squared < nearestSquared {
        nearestSquared = squared
        nearest = foot
      }
    }
  }
  guard let nearest, !(nearestSquared > thresholdPx * thresholdPx) else {
    return EditSnap(position: position, isSnapped: false)
  }
  let snapped = projection.position([nearest.x, nearest.y])
  return EditSnap(position: lngLat(snapped), isSnapped: true)
}

/// lngLat is a position's longitude and latitude, each 0 where the position states none.
private func lngLat(_ position: [Double]) -> [Double] {
  [position.first ?? 0, position.count > 1 ? position[1] : 0]
}

/// pixel is a point of the screen as its two coordinates, each 0 where the point states none.
private func pixel(_ point: [Double]) -> (x: Double, y: Double) {
  (point.first ?? 0, point.count > 1 ? point[1] : 0)
}

/// footOnEdge is the point of the edge from `start` to `end` nearest `point`: the foot of the
/// perpendicular, held to the edge's ends, and the start of an edge of no length. A parameter that
/// is no number stays one, as the foot it names.
private func footOnEdge(
  _ point: (x: Double, y: Double), from start: (x: Double, y: Double),
  to end: (x: Double, y: Double)
) -> (x: Double, y: Double) {
  let dx = end.x - start.x
  let dy = end.y - start.y
  let squaredLength = dx * dx + dy * dy
  if squaredLength == 0 {
    return start
  }
  let along = ((point.x - start.x) * dx + (point.y - start.y) * dy) / squaredLength
  let held = along > 0 ? (along < 1 ? along : 1) : (along.isNaN ? along : 0)
  return (start.x + held * dx, start.y + held * dy)
}

/// squaredDistance is the square of the distance between two points of the screen.
private func squaredDistance(_ a: (x: Double, y: Double), _ b: (x: Double, y: Double)) -> Double {
  let dx = a.x - b.x
  let dy = a.y - b.y
  return dx * dx + dy * dy
}
