/// SearchQueryChange is what a query a reader typed asks of a search, after the query it last
/// settled on: a round for the query as it is asked, a search cleared, or nothing.
///
/// Two are equal where they are the same change, a round's query written with the same scalars.
public enum SearchQueryChange: Sendable, Hashable {
  /// ask is a round to ask, for `query`, the typed query trimmed of the white space at its ends,
  /// which is the round's identity.
  case ask(query: String)
  /// clear settles an empty search and asks nothing: the query trims to nothing.
  case clear
  /// unchanged asks nothing: the query trims to the one already settled.
  case unchanged

  /// Two changes are equal where they are of one kind, a round's query the same scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.ask(let left), .ask(let right)): return sameText(left, right)
    case (.clear, .clear), (.unchanged, .unchanged): return true
    default: return false
    }
  }

  /// hash feeds the kind and a round's query.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .ask(let query):
      hasher.combine(0)
      hasher.combine(query)
    case .clear:
      hasher.combine(1)
    case .unchanged:
      hasher.combine(2)
    }
  }
}
