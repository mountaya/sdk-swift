/// PreferenceOption is one option of a preference a preferences picker offers
/// (`geo.units.preference-choices`): the value a press on it asks for, what it is labelled with,
/// and whether the set the picker is made over holds it.
public struct PreferenceOption: Sendable, Hashable {
  /// value is the value the preference takes when the option is pressed.
  public var value: PreferenceValue
  /// label is what the option is labelled with.
  public var label: PreferenceLabel
  /// isChecked is whether the set holds the option, a language as the map reads one.
  public var isChecked: Bool

  /// Creates an option of `value`, labelled `label`, checked where `isChecked` says so.
  public init(value: PreferenceValue, label: PreferenceLabel, isChecked: Bool) {
    self.value = value
    self.label = label
    self.isChecked = isChecked
  }
}
