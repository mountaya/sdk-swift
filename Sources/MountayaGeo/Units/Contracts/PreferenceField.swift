/// PreferenceField is a preference a preferences picker offers, a member of `UnitPreferences`, its
/// raw value the contract's spelling and the key of the word heading it in the elements'
/// `preferences` section (`geo.units.preference-choices`).
public enum PreferenceField: String, Sendable, Hashable, CaseIterable {
  /// length is the measurement system lengths are stated in.
  case length
  /// pace is the form a travel rate takes.
  case pace
  /// slope is the notation a slope is stated in.
  case slope
  /// temperature is the scale a temperature is stated in.
  case temperature
  /// language is the language the reader reads, which the map labels in too.
  case language
}
