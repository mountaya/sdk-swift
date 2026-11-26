/// HighlightPart is one run of a title as a search result draws it: `text`, as the title writes
/// it, and whether the query matched it. The parts of a title, joined in order, are the title.
///
/// Two are equal where they hold the same run, scalar for scalar, and the same match: a run is
/// compared as it is written, never by canonical equivalence, so `é` and an `e` with a combining
/// acute are two runs.
public struct HighlightPart: Sendable, Hashable {
  /// text is the run, as the title spells it.
  public var text: String
  /// match is whether the run is part of what the query matched.
  public var match: Bool

  /// Creates a run of a title and whether the query matched it.
  public init(text: String, match: Bool) {
    self.text = text
    self.match = match
  }

  /// Two parts are equal where they hold the same scalars and the same match.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.text, rhs.text) && lhs.match == rhs.match
  }

  /// hash feeds the run and the match.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(text)
    hasher.combine(match)
  }
}
