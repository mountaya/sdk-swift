/// CurveColor is a stretch of an itinerary its profile's curve is painted in a colour of its own
/// (`geo.profile.curve-stops`): its two ends in meters from the itinerary's start, in either order,
/// and its colour, any CSS colour, painted as given, since it is data and not a theme token.
///
/// Two are equal where they hold the same numbers and the colours are written alike, as every
/// value of the geo layer compares.
public struct CurveColor: ProfileSpan, Sendable, Hashable {
  /// from is where the stretch starts, in meters from the start of the itinerary.
  public var from: Double
  /// to is where the stretch ends, in meters from the start of the itinerary.
  public var to: Double
  /// color is the colour the stretch is painted in.
  public var color: String

  /// Creates a coloured stretch from its two ends and its colour.
  public init(from: Double, to: Double, color: String) {
    self.from = from
    self.to = to
    self.color = color
  }

  /// Two stretches are equal where both ends are the same numbers and the colours are written
  /// alike.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.from, rhs.from) && sameNumber(lhs.to, rhs.to) && sameText(lhs.color, rhs.color)
  }

  /// hash feeds both ends as the same-number relation reads them, then the colour.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: from)
    hasher.combine(sameNumber: to)
    hasher.combine(color)
  }
}
