/// AltitudeRange is a stretch's altitude band, its lowest and its highest altitude in meters above
/// sea level, as a segment table states it where both are known (`geo.profile.segment-table-cells`)
/// and `formatAltitudeRange(min:max:units:)` writes it.
///
/// Two are equal where they hold the same numbers, as every value of the geo layer compares.
public struct AltitudeRange: Sendable, Hashable {
  /// min is the lowest altitude, in meters above sea level.
  public var min: Double
  /// max is the highest altitude, in meters above sea level.
  public var max: Double

  /// Creates a band from its lowest and highest altitude.
  public init(min: Double, max: Double) {
    self.min = min
    self.max = max
  }

  /// Two bands are equal where both numbers are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.min, rhs.min) && sameNumber(lhs.max, rhs.max)
  }

  /// hash feeds both numbers as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: min)
    hasher.combine(sameNumber: max)
  }
}
