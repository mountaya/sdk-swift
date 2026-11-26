import MountayaGeo

/// WaypointEdit is a waypoint being placed on a map: the waypoint's id, where it was placed, and
/// whether the edit's magnet placed it on one of the map's active segments (`map.edit.snap`).
///
/// It is what `MapEngine.beginWaypointEdit(_:at:)` opens and `MapEngine.endWaypointEdit()`
/// answers. Two are equal where every member is the same, a position by the same-number relation
/// and a text by its scalars, as every Geo value compares.
public struct WaypointEdit: Sendable, Equatable {
  /// waypointId is the id of the waypoint the edit places, the app's own.
  public let waypointId: String
  /// position is where the waypoint was placed, `[longitude, latitude]`, or nil before it is.
  public var position: [Double]?
  /// isSnapped is true where the magnet moved the waypoint onto an active segment.
  public var isSnapped: Bool

  /// Creates an edit of the waypoint `waypointId`, placed at `position` or not yet.
  public init(waypointId: String, position: [Double]? = nil, isSnapped: Bool = false) {
    self.waypointId = waypointId
    self.position = position
    self.isSnapped = isSnapped
  }

  /// Two edits are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard sameText(lhs.waypointId, rhs.waypointId), lhs.isSnapped == rhs.isSnapped else {
      return false
    }
    switch (lhs.position, rhs.position) {
    case (nil, nil): return true
    case (let a?, let b?): return sameNumbers(a, b)
    default: return false
    }
  }
}
