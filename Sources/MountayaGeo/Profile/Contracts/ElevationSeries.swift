/// ElevationSeries is an itinerary read for its profile: cumulative distance against altitude, the
/// input every other profile rule takes.
///
/// `totalDistance` is the whole itinerary's, whether or not it carried elevation, so a flat 2D
/// itinerary still states how long it is, and `points` holds only the vertices that carried an
/// altitude, thinned to the series' ceiling. The altitude range is the whole line's, thinned or
/// not. Two are equal where they hold the same samples and the same numbers, as every value of the
/// geo layer compares.
public struct ElevationSeries: Sendable, Hashable {
  /// points is the samples, ascending by distance, each numbered by its place here.
  public var points: [ElevationPoint]
  /// totalDistance is the meters over every vertex walked, including the ones that carried no
  /// altitude.
  public var totalDistance: Double
  /// minElevation is the lowest altitude any vertex carried, or nil where none carried one.
  public var minElevation: Double?
  /// maxElevation is the highest altitude any vertex carried, or nil where none carried one.
  public var maxElevation: Double?

  /// hasElevation is whether any vertex carried an altitude, which is whether the series has a
  /// sample.
  public var hasElevation: Bool { !points.isEmpty }

  /// Creates a series from its samples, its length and its altitude range.
  public init(
    points: [ElevationPoint], totalDistance: Double, minElevation: Double?, maxElevation: Double?
  ) {
    self.points = points
    self.totalDistance = totalDistance
    self.minElevation = minElevation
    self.maxElevation = maxElevation
  }

  /// Two series are equal where every sample and every figure is.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.points == rhs.points && sameNumber(lhs.totalDistance, rhs.totalDistance)
      && sameNumber(lhs.minElevation, rhs.minElevation)
      && sameNumber(lhs.maxElevation, rhs.maxElevation)
  }

  /// hash feeds every field as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(points)
    hasher.combine(sameNumber: totalDistance)
    hasher.combine(sameNumber: minElevation)
    hasher.combine(sameNumber: maxElevation)
  }
}
