/// walkLine walks a line from the distance `start`, adding `legLength` of each leg between two
/// vertices that name a place, and answers the distance at its last vertex. `visit` is told every
/// vertex in order, with the distance it stands at and its index: a vertex that names no place is
/// told as nil, standing at the distance of the last that did, and the leg after it is measured
/// from that one.
///
/// It is the one walk of a line every profile rule reads distances along. A line is walked on its
/// own: the jump from the end of one line to the start of the next costs nothing, because a caller
/// walks the next from the distance this one answers.
func walkLine(
  _ line: [[Double]],
  from start: Double,
  legLength: ([Double], [Double]) -> Double,
  visit: (_ distance: Double, _ vertex: [Double]?, _ index: Int) -> Void = { _, _, _ in }
) -> Double {
  var distance = start
  var previous: [Double]?
  for (index, vertex) in line.enumerated() {
    guard namesPlace(vertex) else {
      visit(distance, nil, index)
      continue
    }
    if let from = previous {
      distance += legLength(from, vertex)
    }
    previous = vertex
    visit(distance, vertex, index)
  }
  return distance
}
