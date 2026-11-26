/// routeLengthMeters is the length of a line in meters, the sum of the great-circle distances
/// between its vertices: the last of its `cumulativeMeters(_:)`, and 0 for a line with no vertex.
/// A vertex that names no place is bridged, as `cumulativeMeters(_:)` reads it.
public func routeLengthMeters(_ line: [[Double]]) -> Double {
  cumulativeMeters(line).last ?? 0
}
