/// ProfileClass is a stretch of an itinerary classified into a colour and a word: what a hover card
/// names and colours where a cursor stands in it (`geo.profile.stretch-at`), and what the curve is
/// painted in. A caller states its own taxonomy this way, a surface, a way type or a sponsor's
/// sectors, and `slopeStretches(_:buckets:)` computes the one a profile derives, its steepness.
///
/// Two are equal where they hold the same numbers and the same texts, as every value of the geo
/// layer compares.
public struct ProfileClass: ProfileSpan, Sendable, Hashable {
  /// from is where the stretch starts, in meters from the start of the itinerary.
  public var from: Double
  /// to is where the stretch ends, in meters from the start of the itinerary.
  public var to: Double
  /// color is the colour the stretch is painted in, any CSS colour, painted as given.
  public var color: String
  /// label is the word the stretch reads as: a caller's own word, or the key of a slope bucket.
  public var label: String

  /// Creates a classified stretch from its two ends, its colour and its word.
  public init(from: Double, to: Double, color: String, label: String) {
    self.from = from
    self.to = to
    self.color = color
    self.label = label
  }

  /// Two stretches are equal where both ends are the same numbers and both texts are written
  /// alike.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.from, rhs.from) && sameNumber(lhs.to, rhs.to)
      && sameText(lhs.color, rhs.color) && sameText(lhs.label, rhs.label)
  }

  /// hash feeds both ends as the same-number relation reads them, then the texts.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: from)
    hasher.combine(sameNumber: to)
    hasher.combine(color)
    hasher.combine(label)
  }
}
