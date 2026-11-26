/// Climb is one categorized climb on an itinerary's distance axis: the stretch from its foot to its
/// summit, the summit's altitude, its average grade and its category.
///
/// Two are equal where they hold the same numbers and the same category, as every value of the geo
/// layer compares.
public struct Climb: Sendable, Hashable {
  /// startKm is where the climb's foot stands, in kilometers from the itinerary's start.
  public var startKm: Double
  /// endKm is where its summit stands, in kilometers from the itinerary's start.
  public var endKm: Double
  /// peakElevation is the summit's altitude, in meters.
  public var peakElevation: Double
  /// avgGradePercent is the rise over the run from the foot to the summit, in percent.
  public var avgGradePercent: Double
  /// category is the category its score reaches.
  public var category: ClimbCategory

  /// Creates a climb from its foot, its summit, the summit's altitude, its grade and its category.
  public init(
    startKm: Double, endKm: Double, peakElevation: Double, avgGradePercent: Double,
    category: ClimbCategory
  ) {
    self.startKm = startKm
    self.endKm = endKm
    self.peakElevation = peakElevation
    self.avgGradePercent = avgGradePercent
    self.category = category
  }

  /// Two climbs are equal where every number is the same number and the category is one.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.startKm, rhs.startKm) && sameNumber(lhs.endKm, rhs.endKm)
      && sameNumber(lhs.peakElevation, rhs.peakElevation)
      && sameNumber(lhs.avgGradePercent, rhs.avgGradePercent) && lhs.category == rhs.category
  }

  /// hash feeds every number as the same-number relation reads it, then the category.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: startKm)
    hasher.combine(sameNumber: endKm)
    hasher.combine(sameNumber: peakElevation)
    hasher.combine(sameNumber: avgGradePercent)
    hasher.combine(category)
  }
}
