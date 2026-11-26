/// RouteProfilePoint is one sample a climb is read on: how far along the itinerary it stands, in
/// kilometers, and the ground's altitude there.
///
/// The distance is in kilometers because the climb's windows are read in kilometers, and a run
/// measured in kilometers is not always the same double as one measured in meters and divided:
/// 1.2 − 0.9 is under 0.3. Two are equal where they hold the same numbers, as every value of the
/// geo layer compares.
public struct RouteProfilePoint: Sendable, Hashable {
  /// distanceKm is the kilometers from the start of the itinerary.
  public var distanceKm: Double
  /// elevation is the meters above sea level.
  public var elevation: Double

  /// Creates a sample from its distance in kilometers and its altitude.
  public init(distanceKm: Double, elevation: Double) {
    self.distanceKm = distanceKm
    self.elevation = elevation
  }

  /// Two samples are equal where both numbers are the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.distanceKm, rhs.distanceKm) && sameNumber(lhs.elevation, rhs.elevation)
  }

  /// hash feeds both numbers as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: distanceKm)
    hasher.combine(sameNumber: elevation)
  }
}
