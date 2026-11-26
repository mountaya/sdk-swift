/// EditSnap is where an edit's magnet places a point the pointer holds: the position the point
/// takes, and whether the magnet moved it onto a line.
///
/// A point the magnet leaves is the pointer's position as it was given, an altitude included; one
/// it moves is the position its projection reads back, `[longitude, latitude]`.
struct EditSnap: Sendable {
  /// position is the position the point takes.
  let position: [Double]
  /// isSnapped is true where the magnet moved the point onto a line.
  let isSnapped: Bool
}
