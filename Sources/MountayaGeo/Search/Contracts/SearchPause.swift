/// SearchPause is how long a query goes unchanged before a search asks a round for it: a length of
/// time of zero or more, zero asking a round as the query is typed (`geo.search.typing-pause`).
///
/// Its initializer is the refusal: a pause below zero is no `SearchPause`, so a search is refused it
/// as it is built, before it asks or shows anything, as a cap outside 1 to `searchLimitMax` is no
/// `SearchLimit`. A pause is a length of time, and one below zero is a search set up wrong rather
/// than a wish to ask at once.
public struct SearchPause: Sendable, Hashable {
  /// duration is the pause, zero or more.
  public let duration: Duration

  /// Creates the pause `duration`, or nil where it is below zero.
  public init?(_ duration: Duration) {
    guard duration >= .zero else { return nil }
    self.duration = duration
  }

  /// standard is the pause a search waits where it is given none, `searchTypingPause`.
  public static let standard = SearchPause(checked: searchTypingPause)

  /// Creates a pause the caller has held to zero or more.
  private init(checked duration: Duration) {
    self.duration = duration
  }
}
