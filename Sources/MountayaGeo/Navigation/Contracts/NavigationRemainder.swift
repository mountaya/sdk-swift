/// NavigationRemainder is what is left of a stretch of a route, to its next maneuver or to its
/// arrival: the measured length, and the time the steps state for it (`geo.navigation.progress`).
///
/// Two are equal where both members are, each as the same number, `NaN` the same as `NaN` and 0
/// another than -0, an absent duration the same only as another absent one.
public struct NavigationRemainder: Sendable, Hashable {
  /// distance is the length left, in meters, measured along the route's line.
  public var distance: Double
  /// duration is the time left in seconds, or nil where a step it reads states no duration.
  public var duration: Double?

  /// Creates a remainder from the length and the time left.
  public init(distance: Double, duration: Double?) {
    self.distance = distance
    self.duration = duration
  }

  /// Two remainders are equal where both figures are the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.distance, rhs.distance) && sameNumber(lhs.duration, rhs.duration)
  }

  /// hash feeds both figures as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: duration)
  }
}
