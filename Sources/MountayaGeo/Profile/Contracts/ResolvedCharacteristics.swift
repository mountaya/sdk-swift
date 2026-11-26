import MountayaClient

/// ResolvedCharacteristics is an itinerary's figures as a surface states them, each the one stated
/// over the one derived (`resolveCharacteristics(_:stated:)`): what the server computed where it
/// computed it, and what the profile reads off the geometry where it did not, plus the three no
/// geometry answers, the duration, the steepest descent and the trail difficulty.
///
/// Meters, seconds and degrees, a loss stated positive, every figure nil where there is none. Two
/// are equal where they hold the same figures, each number by the same-number relation and each
/// difficulty by its scalars, as every value of the geo layer compares.
public struct ResolvedCharacteristics: Sendable, Hashable {
  /// distance is the itinerary's length, in meters.
  public var distance: Double?
  /// duration is the seconds the itinerary is expected to take.
  public var duration: Double?
  /// ascent is the meters climbed.
  public var ascent: Double?
  /// descent is the meters lost, stated positive.
  public var descent: Double?
  /// altitudeMin is the lowest altitude, in meters above sea level.
  public var altitudeMin: Double?
  /// altitudeMax is the highest altitude, in meters above sea level.
  public var altitudeMax: Double?
  /// slopeMin is the steepest descending grade, in degrees, negative.
  public var slopeMin: Double?
  /// slopeMax is the steepest ascending grade, in degrees.
  public var slopeMax: Double?
  /// trailDifficultyMin is the easiest stretch's difficulty, as the itinerary writes it.
  public var trailDifficultyMin: RestSchema.TrailDifficultyType?
  /// trailDifficultyMax is the hardest stretch's difficulty, as the itinerary writes it.
  public var trailDifficultyMax: RestSchema.TrailDifficultyType?

  /// Creates the figures of an itinerary, each nil unless given.
  public init(
    distance: Double? = nil,
    duration: Double? = nil,
    ascent: Double? = nil,
    descent: Double? = nil,
    altitudeMin: Double? = nil,
    altitudeMax: Double? = nil,
    slopeMin: Double? = nil,
    slopeMax: Double? = nil,
    trailDifficultyMin: RestSchema.TrailDifficultyType? = nil,
    trailDifficultyMax: RestSchema.TrailDifficultyType? = nil
  ) {
    self.distance = distance
    self.duration = duration
    self.ascent = ascent
    self.descent = descent
    self.altitudeMin = altitudeMin
    self.altitudeMax = altitudeMax
    self.slopeMin = slopeMin
    self.slopeMax = slopeMax
    self.trailDifficultyMin = trailDifficultyMin
    self.trailDifficultyMax = trailDifficultyMax
  }

  /// numbers is every figure but the difficulties, in the order the type declares them.
  private var numbers: [Double?] {
    [distance, duration, ascent, descent, altitudeMin, altitudeMax, slopeMin, slopeMax]
  }

  /// Two are equal where every figure is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    zip(lhs.numbers, rhs.numbers).allSatisfy { sameNumber($0, $1) }
      && sameText(lhs.trailDifficultyMin, rhs.trailDifficultyMin)
      && sameText(lhs.trailDifficultyMax, rhs.trailDifficultyMax)
  }

  /// hash feeds every figure, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    for number in numbers {
      hasher.combine(sameNumber: number)
    }
    hasher.combine(trailDifficultyMin)
    hasher.combine(trailDifficultyMax)
  }
}
