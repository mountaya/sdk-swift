import MountayaClient

/// ItinerarySegmentRowMetrics is what one stretch of an itinerary measures, as a segment row states
/// it (`geo.profile.segment-rows`), and, any of its figures given, what a caller states over the
/// figures a row reads off the itinerary's geometry: the server's own, computed over the full
/// track, where the geometry can only estimate them.
///
/// Meters and seconds throughout, a loss stated positive as the wire states it, and every figure
/// nil where there is none, since an itinerary with no altitude has a length and nothing else. Two
/// are equal where they hold the same figures, each number by the same-number relation and the
/// difficulty by its scalars, as every value of the geo layer compares.
public struct ItinerarySegmentRowMetrics: Sendable, Hashable {
  /// distance is the meters from the start of the itinerary to the end of the stretch.
  public var distance: Double?
  /// sectionDistance is the meters the stretch covers alone.
  public var sectionDistance: Double?
  /// ascent is the meters climbed from the start of the itinerary to the end of the stretch.
  public var ascent: Double?
  /// descent is the meters lost from the start of the itinerary to the end of the stretch, stated
  /// positive.
  public var descent: Double?
  /// sectionAscent is the meters the stretch climbs alone.
  public var sectionAscent: Double?
  /// sectionDescent is the meters the stretch loses alone, stated positive.
  public var sectionDescent: Double?
  /// altitudeMin is the lowest altitude on the stretch, in meters above sea level.
  public var altitudeMin: Double?
  /// altitudeMax is the highest altitude on the stretch, in meters above sea level.
  public var altitudeMax: Double?
  /// duration is the seconds the stretch is expected to take, which no geometry implies.
  public var duration: Double?
  /// difficulty is the stretch's grade as the itinerary's taxonomy writes it, which no geometry
  /// implies and no element ranks.
  public var difficulty: RestSchema.TrailDifficultyType?

  /// Creates the figures of a stretch, each nil unless given.
  public init(
    distance: Double? = nil,
    sectionDistance: Double? = nil,
    ascent: Double? = nil,
    descent: Double? = nil,
    sectionAscent: Double? = nil,
    sectionDescent: Double? = nil,
    altitudeMin: Double? = nil,
    altitudeMax: Double? = nil,
    duration: Double? = nil,
    difficulty: RestSchema.TrailDifficultyType? = nil
  ) {
    self.distance = distance
    self.sectionDistance = sectionDistance
    self.ascent = ascent
    self.descent = descent
    self.sectionAscent = sectionAscent
    self.sectionDescent = sectionDescent
    self.altitudeMin = altitudeMin
    self.altitudeMax = altitudeMax
    self.duration = duration
    self.difficulty = difficulty
  }

  /// numbers is every figure but the difficulty, in the order the type declares them.
  private var numbers: [Double?] {
    [
      distance, sectionDistance, ascent, descent, sectionAscent, sectionDescent, altitudeMin,
      altitudeMax, duration,
    ]
  }

  /// Two are equal where every figure is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    zip(lhs.numbers, rhs.numbers).allSatisfy { sameNumber($0, $1) }
      && sameText(lhs.difficulty, rhs.difficulty)
  }

  /// hash feeds every figure, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    for number in numbers {
      hasher.combine(sameNumber: number)
    }
    hasher.combine(difficulty)
  }
}
