/// PlacedSpan is a stretch placed under a profile's chart, its band strip or its section chips
/// (`geo.profile.window-spans`): the stretch as given, its place in the list given, its two ends in
/// order, and where its start and its end are drawn across the plot, held to the frame, the end
/// always past the start.
public struct PlacedSpan<Span: ProfileSpan>: Sendable {
  /// span is the stretch as the caller gave it.
  public var span: Span
  /// index is the stretch's place in the list the caller gave, from zero.
  public var index: Int
  /// from is where the stretch starts, in meters from the start of the itinerary: the lower of its
  /// ends.
  public var from: Double
  /// to is where the stretch ends: the higher of its ends.
  public var to: Double
  /// start is how far across the plot the stretch's start is drawn.
  public var start: Double
  /// end is how far across the plot the stretch's end is drawn.
  public var end: Double

  /// Creates a placed stretch from the stretch, its place in the list, its ends and where they are
  /// drawn.
  public init(span: Span, index: Int, from: Double, to: Double, start: Double, end: Double) {
    self.span = span
    self.index = index
    self.from = from
    self.to = to
    self.start = start
    self.end = end
  }
}

extension PlacedSpan: Equatable, Hashable where Span: Hashable {
  /// Two placed stretches are equal where the stretches are, at one place in the list, with the
  /// same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.span == rhs.span && lhs.index == rhs.index && sameNumber(lhs.from, rhs.from)
      && sameNumber(lhs.to, rhs.to) && sameNumber(lhs.start, rhs.start)
      && sameNumber(lhs.end, rhs.end)
  }

  /// hash feeds the stretch, its place in the list, then each number as the same-number relation
  /// reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(span)
    hasher.combine(index)
    hasher.combine(sameNumber: from)
    hasher.combine(sameNumber: to)
    hasher.combine(sameNumber: start)
    hasher.combine(sameNumber: end)
  }
}
