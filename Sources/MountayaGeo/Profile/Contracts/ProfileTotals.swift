/// ProfileTotals is the figures of an itinerary, or of one stretch of it, read off its elevation
/// series: its length, the meters it climbs and drops, its altitude band and its steepest grade.
/// Every figure but the length is nil where the series has no sample to read it from, since a 2D
/// itinerary has no ascent.
///
/// Two are equal where they hold the same numbers, as every value of the geo layer compares.
public struct ProfileTotals: Sendable, Hashable {
  /// distance is the length, in meters: the itinerary's, or the stretch's own.
  public var distance: Double
  /// ascent is the meters climbed, rises under the noise threshold left out.
  public var ascent: Double?
  /// descent is the meters dropped, falls under the noise threshold left out.
  public var descent: Double?
  /// elevationMin is the lowest altitude, in meters.
  public var elevationMin: Double?
  /// elevationMax is the highest altitude, in meters.
  public var elevationMax: Double?
  /// gradeMax is the steepest ascending grade over a run of the grade window, in degrees, never
  /// under 0.
  public var gradeMax: Double?

  /// Creates totals from their figures.
  public init(
    distance: Double, ascent: Double?, descent: Double?, elevationMin: Double?,
    elevationMax: Double?, gradeMax: Double?
  ) {
    self.distance = distance
    self.ascent = ascent
    self.descent = descent
    self.elevationMin = elevationMin
    self.elevationMax = elevationMax
    self.gradeMax = gradeMax
  }

  /// Two totals are equal where every figure is the same number, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.distance, rhs.distance) && sameNumber(lhs.ascent, rhs.ascent)
      && sameNumber(lhs.descent, rhs.descent) && sameNumber(lhs.elevationMin, rhs.elevationMin)
      && sameNumber(lhs.elevationMax, rhs.elevationMax) && sameNumber(lhs.gradeMax, rhs.gradeMax)
  }

  /// hash feeds every figure as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: ascent)
    hasher.combine(sameNumber: descent)
    hasher.combine(sameNumber: elevationMin)
    hasher.combine(sameNumber: elevationMax)
    hasher.combine(sameNumber: gradeMax)
  }
}
