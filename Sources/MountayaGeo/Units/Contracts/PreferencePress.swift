import MountayaClient

/// PreferencePress is what a press on an option of a preferences picker asks for
/// (`geo.units.preference-choices`): the whole preference set, and the language the map relabels
/// in where the press is on a language.
///
/// Two are equal where they ask for the same, a language by its scalars.
public struct PreferencePress: Sendable, Hashable {
  /// next is the set the press asks for: the set it was made over, with one preference changed.
  public var next: UnitPreferences
  /// relabel is the language the map relabels in, for a press on a language, and nil otherwise.
  public var relabel: RestSchema.Language?

  /// Creates a press asking for `next`, relabelling the map in `relabel` where it names one.
  public init(next: UnitPreferences, relabel: RestSchema.Language?) {
    self.next = next
    self.relabel = relabel
  }

  /// Two presses are equal where they ask for the same set and the same relabelling.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.next == rhs.next && sameText(lhs.relabel?.rawValue, rhs.relabel?.rawValue)
  }

  /// hash feeds the set and the relabelling.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(next)
    hasher.combine(relabel)
  }
}
