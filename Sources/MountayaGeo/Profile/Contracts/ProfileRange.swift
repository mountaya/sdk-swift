/// ProfileRange is a stretch of an itinerary's distance axis, its two ends in meters from the
/// itinerary's start: the window a profile is drawn over, and the stretch a reader points at.
///
/// Its ends may be given in either order, and every rule that reads one reads it in order. Two are
/// equal where they hold the same numbers, as every value of the geo layer compares.
public struct ProfileRange: ProfileSpan, Sendable, Hashable {
  /// from is where the stretch starts, in meters from the start of the itinerary.
  public var from: Double
  /// to is where the stretch ends, in meters from the start of the itinerary.
  public var to: Double

  /// Creates a stretch from its two ends.
  public init(from: Double, to: Double) {
    self.from = from
    self.to = to
  }

  /// Two stretches are equal where both ends are the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.from, rhs.from) && sameNumber(lhs.to, rhs.to)
  }

  /// hash feeds both ends as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: from)
    hasher.combine(sameNumber: to)
  }
}
