/// ProfileWaypoint is a waypoint a caller places on an itinerary's distance axis: given at a
/// position, it stands at every pass of the line near it, and given at a distance, it stands there.
///
/// Two are equal where they are of one kind and hold the same id and the same numbers, as every
/// value of the geo layer compares, the id by its scalars.
public enum ProfileWaypoint: Sendable, Hashable {
  /// atPosition is a waypoint given where it stands on the ground, `[longitude, latitude]` in
  /// degrees.
  case atPosition(id: String, position: [Double])
  /// atDistance is a waypoint given where it stands on the axis already, in meters from the start
  /// of the itinerary.
  case atDistance(id: String, distance: Double)

  /// id is the caller's own id, which a placement's key is built from.
  public var id: String {
    switch self {
    case .atPosition(let id, _), .atDistance(let id, _): id
    }
  }

  /// Two waypoints are equal where they are of one kind, with one id and the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.atPosition(let a, let first), .atPosition(let b, let second)):
      sameText(a, b) && sameNumbers(first, second)
    case (.atDistance(let a, let first), .atDistance(let b, let second)):
      sameText(a, b) && sameNumber(first, second)
    default:
      false
    }
  }

  /// hash feeds the kind, the id, then the numbers as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .atPosition(let id, let position):
      hasher.combine(0)
      hasher.combine(id)
      hasher.combine(sameNumbers: position)
    case .atDistance(let id, let distance):
      hasher.combine(1)
      hasher.combine(id)
      hasher.combine(sameNumber: distance)
    }
  }
}
