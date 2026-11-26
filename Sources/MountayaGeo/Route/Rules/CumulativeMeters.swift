/// cumulativeMeters is the distance in meters along a line to each of its vertices,
/// `[longitude, latitude]` in degrees: 0 at the first, and each later one the one before plus the
/// great-circle distance between them, so the last is the line's length. The answer has one
/// distance per vertex, ascending, and the line is measured identically by every rule that reads a
/// distance along it.
///
/// A vertex that names no place, short of a longitude or a latitude or with either not finite,
/// keeps its index and stands at the distance of the last vertex that did, 0 before any, and the
/// vertex after it is measured from that one, as every walk of a line reads it. An empty line
/// answers an empty list.
///
/// Each measurement is recorded by the `MeasureProbe` a test holds, and by nothing otherwise.
public func cumulativeMeters(_ line: [[Double]]) -> [Double] {
  MeasureProbe.current?.record(line)
  var distances: [Double] = []
  distances.reserveCapacity(line.count)
  var running: Double = 0
  var previous: [Double]?
  for vertex in line {
    if namesPlace(vertex) {
      if let from = previous {
        running += haversineMeters(from: from, to: vertex)
      }
      previous = vertex
    }
    distances.append(running)
  }
  return distances
}
