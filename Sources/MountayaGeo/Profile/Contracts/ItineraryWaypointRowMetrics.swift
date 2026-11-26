/// ItineraryWaypointRowMetrics is what one waypoint row states (`geo.profile.waypoint-rows`): the
/// running distance to its place, the figures of the stretch that reaches it, the running climb and
/// loss, and the place's own altitude, a single reading, since a place is a point.
///
/// Meters throughout, a loss stated positive, every figure but the distance nil where there is
/// none. Two are equal where they hold the same figures, each number by the same-number relation,
/// as every value of the geo layer compares.
public struct ItineraryWaypointRowMetrics: Sendable, Hashable {
  /// distance is the meters from the start of the itinerary to the place.
  public var distance: Double
  /// sectionDistance is the meters covered since the previous place, or since the start for the
  /// first row.
  public var sectionDistance: Double?
  /// ascent is the meters climbed from the start of the itinerary to the place.
  public var ascent: Double?
  /// descent is the meters lost from the start of the itinerary to the place, stated positive.
  public var descent: Double?
  /// sectionAscent is the meters climbed since the previous place.
  public var sectionAscent: Double?
  /// sectionDescent is the meters lost since the previous place, stated positive.
  public var sectionDescent: Double?
  /// altitude is the curve's altitude at the place, in meters above sea level.
  public var altitude: Double?

  /// Creates a row's figures from the running distance and the figures given.
  public init(
    distance: Double,
    sectionDistance: Double? = nil,
    ascent: Double? = nil,
    descent: Double? = nil,
    sectionAscent: Double? = nil,
    sectionDescent: Double? = nil,
    altitude: Double? = nil
  ) {
    self.distance = distance
    self.sectionDistance = sectionDistance
    self.ascent = ascent
    self.descent = descent
    self.sectionAscent = sectionAscent
    self.sectionDescent = sectionDescent
    self.altitude = altitude
  }

  /// numbers is every figure, in the order the type declares them.
  private var numbers: [Double?] {
    [distance, sectionDistance, ascent, descent, sectionAscent, sectionDescent, altitude]
  }

  /// Two are equal where every figure is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    zip(lhs.numbers, rhs.numbers).allSatisfy { sameNumber($0, $1) }
  }

  /// hash feeds every figure as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    for number in numbers {
      hasher.combine(sameNumber: number)
    }
  }
}
