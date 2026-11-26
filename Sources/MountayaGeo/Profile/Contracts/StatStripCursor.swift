/// StatStripCursor is where a scrub stands, as the stat strip reads it (`geo.profile.stat-strip`):
/// the distance and the altitude of the sample the cursor stands on, and the grade there.
///
/// Two are equal where they hold the same numbers, as every value of the geo layer compares.
public struct StatStripCursor: Sendable, Hashable {
  /// distance is the meters from the start of the itinerary of the sample the cursor stands on.
  public var distance: Double
  /// elevation is that sample's altitude, in meters above sea level.
  public var elevation: Double
  /// grade is the grade there, in degrees, nil where none reads.
  public var grade: Double?

  /// Creates a cursor from its sample's distance and altitude and the grade there.
  public init(distance: Double, elevation: Double, grade: Double?) {
    self.distance = distance
    self.elevation = elevation
    self.grade = grade
  }

  /// Two cursors are equal where every number is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.distance, rhs.distance) && sameNumber(lhs.elevation, rhs.elevation)
      && sameNumber(lhs.grade, rhs.grade)
  }

  /// hash feeds every number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: elevation)
    hasher.combine(sameNumber: grade)
  }
}
