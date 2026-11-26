/// ElevationDomain is the elevation range a profile's curve is drawn against, in meters above sea
/// level: its floor is drawn at the bottom of the plot and its ceiling under its top inset
/// (`geo.profile.plot-scale`).
///
/// Two are equal where they hold the same numbers, as every value of the geo layer compares.
public struct ElevationDomain: Sendable, Hashable {
  /// min is the floor, in meters above sea level.
  public var min: Double
  /// max is the ceiling, in meters above sea level.
  public var max: Double

  /// Creates a domain from its floor and its ceiling.
  public init(min: Double, max: Double) {
    self.min = min
    self.max = max
  }

  /// Two domains are equal where the floors and the ceilings are the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.min, rhs.min) && sameNumber(lhs.max, rhs.max)
  }

  /// hash feeds the floor and the ceiling as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: min)
    hasher.combine(sameNumber: max)
  }
}
