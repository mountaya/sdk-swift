/// SearchRowSecondary is the second line under a search result's title: a sentence worded for the
/// reader, an itinerary's distance and ascent for the surface to state in its reader's units, or a
/// collection's count of itineraries for the surface to pluralize in its language.
///
/// Two are equal where they are the same kind holding the same values, each number the same
/// number, `NaN` the same as `NaN` and 0 another than -0, and a sentence the same scalars.
public enum SearchRowSecondary: Sendable, Hashable {
  /// text is a sentence: a category, a figure, the place's region and country.
  case text(String)
  /// metric is an itinerary's length in meters and its ascent in meters, each `nil` where the
  /// search answered none.
  case metric(distance: Double?, ascent: Int?)
  /// count is a collection's count of itineraries, `nil` where the search answered none.
  case count(itineraries: Int?)

  /// Two second lines are equal where they are of one kind and hold the same values.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.text(let left), .text(let right)):
      return sameText(left, right)
    case (.metric(let leftDistance, let leftAscent), .metric(let rightDistance, let rightAscent)):
      return sameNumber(leftDistance, rightDistance) && leftAscent == rightAscent
    case (.count(let left), .count(let right)):
      return left == right
    default:
      return false
    }
  }

  /// hash feeds the kind and its values, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .text(let text):
      hasher.combine(0)
      hasher.combine(text)
    case .metric(let distance, let ascent):
      hasher.combine(1)
      hasher.combine(sameNumber: distance)
      hasher.combine(ascent)
    case .count(let itineraries):
      hasher.combine(2)
      hasher.combine(itineraries)
    }
  }
}
