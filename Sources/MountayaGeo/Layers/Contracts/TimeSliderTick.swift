/// TimeSliderTick is one tick a time slider marks on its track (`geo.layers.time-slider`): the stop
/// it stands at, and the word it carries, by its path as `ElementsScope.word(_:)` reads one,
/// `layers.timeNow`, or nil for a bare tick.
///
/// Two are equal where both members are, a word by its scalars.
public struct TimeSliderTick: Sendable, Equatable {
  /// value is the stop the tick stands at.
  public var value: Int
  /// word is the path of the word the tick carries, `layers.timeMinus2d`, or nil for none.
  public var word: String?

  /// Creates the tick at the stop `value`, carrying the word at `word`, or none.
  public init(value: Int, word: String?) {
    self.value = value
    self.word = word
  }

  /// Two ticks are equal where they stand at one stop and carry the same word, by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.value == rhs.value && sameText(lhs.word, rhs.word)
  }
}
