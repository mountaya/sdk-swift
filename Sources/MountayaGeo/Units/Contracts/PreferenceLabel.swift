/// PreferenceLabel is what an option of a preferences picker is labelled with
/// (`geo.units.preference-choices`): a word of the elements' `preferences` section, or, for a
/// language, its name in itself, which no language translates.
///
/// Two are equal where they are of one kind and spell the same scalars.
public enum PreferenceLabel: Sendable, Hashable {
  /// word is the key of a word of the elements' `preferences` section, `metric`.
  case word(String)
  /// name is a language's name in itself, `Deutsch`, as `languageEndonyms` writes it.
  case name(String)

  /// Two labels are equal where they are of one kind and spell the same scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.word(let a), .word(let b)), (.name(let a), .name(let b)): sameText(a, b)
    default: false
    }
  }

  /// hash feeds the kind and the text.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .word(let word):
      hasher.combine(0)
      hasher.combine(word)
    case .name(let name):
      hasher.combine(1)
      hasher.combine(name)
    }
  }
}
