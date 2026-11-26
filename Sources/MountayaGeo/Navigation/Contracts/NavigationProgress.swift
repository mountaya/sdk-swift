/// NavigationProgress is where a traveller stands on the route they follow, and what is left of
/// it, to the next maneuver and to the arrival (`geo.navigation.progress`): every number a reader
/// is told about a navigation, the same in every SDK for the same route and position.
///
/// Two are equal where every member is, each figure as the same number, `NaN` the same as `NaN`
/// and 0 another than -0.
public struct NavigationProgress: Sendable, Hashable {
  /// along is how far along the route the traveller stands, in meters from its first vertex.
  public var along: Double
  /// step is the index of the step the traveller is in, into the followed route's steps.
  public var step: Int
  /// next is the index of the step after it, whose maneuver is the next, or nil after the last.
  public var next: Int?
  /// toManeuver is what is left to the end of the current step, where the next maneuver is.
  public var toManeuver: NavigationRemainder
  /// toArrival is what is left to the end of the route.
  public var toArrival: NavigationRemainder

  /// Creates a reading from where the traveller stands, the step they are in and the next, and
  /// what is left to the next maneuver and to the arrival.
  public init(
    along: Double, step: Int, next: Int?, toManeuver: NavigationRemainder,
    toArrival: NavigationRemainder
  ) {
    self.along = along
    self.step = step
    self.next = next
    self.toManeuver = toManeuver
    self.toArrival = toArrival
  }

  /// Two readings are equal where every member is, each figure the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.along, rhs.along) && lhs.step == rhs.step && lhs.next == rhs.next
      && lhs.toManeuver == rhs.toManeuver && lhs.toArrival == rhs.toArrival
  }

  /// hash feeds every member, each figure as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: along)
    hasher.combine(step)
    hasher.combine(next)
    hasher.combine(toManeuver)
    hasher.combine(toArrival)
  }
}
