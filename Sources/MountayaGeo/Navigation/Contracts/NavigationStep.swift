import MountayaClient

/// NavigationStep is one turn-by-turn step of a route, in the one vocabulary every navigation rule
/// reads: REST's, whichever surface wrote the route (`geo.navigation.steps`).
///
/// A step covers the inclusive range of the route's vertices from `fromIndex` to `toIndex`, and
/// its `maneuver` is the move a traveller makes where it starts. Its `distance` and `duration` are
/// the figures its surface sent: no rule reads `distance` as a distance, since every distance along
/// a route is measured on its line, and `duration` is what the time left is read from.
///
/// A step read from either surface (`readDirectionsSteps(_:coordinateCount:)`,
/// `readItineraryDirectionsSteps(_:coordinateCount:)`) names a maneuver of the contract's set,
/// `unknown` for one outside it, and no name for an unnamed way; a step written by hand may hold
/// anything, and the rules read it the same way.
///
/// Two are equal where every member is, each figure as the same number, `NaN` the same as `NaN`
/// and 0 another than -0, and each text by its scalars, as every value of the geo layer compares.
public struct NavigationStep: Sendable, Hashable {
  /// fromIndex is the first vertex the step covers, an index into the route's geometry.
  public var fromIndex: Int
  /// toIndex is the last vertex the step covers, an index into the same geometry.
  public var toIndex: Int
  /// maneuver is what the step asks the traveller to do where it starts, a member of REST's
  /// `ManeuverType`.
  public var maneuver: RestSchema.ManeuverType
  /// name is the name of the way the step follows, or nil where the way has none.
  public var name: String?
  /// distance is the step's length in meters as its surface states it, or nil where it states
  /// none.
  public var distance: Double?
  /// duration is the step's duration in seconds as its surface states it, or nil where it states
  /// none.
  public var duration: Double?
  /// exitNumber is the roundabout exit to take as its surface states it, or nil where it states
  /// none.
  public var exitNumber: Int?

  /// Creates a step from its range and its maneuver, and the name and figures it states, none by
  /// default.
  public init(
    fromIndex: Int, toIndex: Int, maneuver: RestSchema.ManeuverType, name: String? = nil,
    distance: Double? = nil, duration: Double? = nil, exitNumber: Int? = nil
  ) {
    self.fromIndex = fromIndex
    self.toIndex = toIndex
    self.maneuver = maneuver
    self.name = name
    self.distance = distance
    self.duration = duration
    self.exitNumber = exitNumber
  }

  /// Two steps are equal where every member is, each figure the same number and each text the
  /// same scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.fromIndex == rhs.fromIndex && lhs.toIndex == rhs.toIndex
      && sameText(lhs.maneuver.rawValue, rhs.maneuver.rawValue) && sameText(lhs.name, rhs.name)
      && sameNumber(lhs.distance, rhs.distance) && sameNumber(lhs.duration, rhs.duration)
      && lhs.exitNumber == rhs.exitNumber
  }

  /// hash feeds every member, each figure as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(fromIndex)
    hasher.combine(toIndex)
    hasher.combine(maneuver)
    hasher.combine(name)
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: duration)
    hasher.combine(exitNumber)
  }
}
