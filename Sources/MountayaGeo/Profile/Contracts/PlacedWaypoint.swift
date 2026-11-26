/// PlacedWaypoint is one placement of a waypoint on an itinerary's distance axis: one pass of the
/// line, so a place the itinerary passes twice is placed twice.
///
/// Two are equal where they hold the same key, the same waypoint and the same number, as every
/// value of the geo layer compares, the key by its scalars.
public struct PlacedWaypoint: Sendable, Hashable {
  /// key is unique per placement: `id#pass`, counting the waypoint's passes from zero, `hut#1`.
  public var key: String
  /// waypoint is the waypoint placed.
  public var waypoint: ProfileWaypoint
  /// distance is the meters from the start of the itinerary.
  public var distance: Double

  /// Creates a placement from its key, its waypoint and its distance.
  public init(key: String, waypoint: ProfileWaypoint, distance: Double) {
    self.key = key
    self.waypoint = waypoint
    self.distance = distance
  }

  /// Two placements are equal where the key and the waypoint are one and the distance the same
  /// number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && lhs.waypoint == rhs.waypoint
      && sameNumber(lhs.distance, rhs.distance)
  }

  /// hash feeds the key, the waypoint, then the distance as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(waypoint)
    hasher.combine(sameNumber: distance)
  }
}
