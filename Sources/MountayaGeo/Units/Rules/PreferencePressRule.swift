import MountayaClient

/// preferencePress is what a press on the option `value` of a preferences picker made over
/// `preferences` asks for (`geo.units.preference-choices`): the whole set, the pressed preference
/// changed and every other as it was, and, for a language, the language the map relabels in, read
/// as a label language (`labelLanguage(_:)`), since a language is a concern of the map's labels as
/// well.
///
/// The set is reported rather than kept: units are an app's own concern, read by surfaces a picker
/// cannot see, so a picker holds no set of its own. A press on the option the set holds reports the
/// set as it stands.
public func preferencePress(_ preferences: UnitPreferences, pressing value: PreferenceValue)
  -> PreferencePress
{
  var next = preferences
  var relabel: RestSchema.Language?
  switch value {
  case .length(let length): next.length = length
  case .pace(let pace): next.pace = pace
  case .slope(let slope): next.slope = slope
  case .temperature(let temperature): next.temperature = temperature
  case .language(let language):
    next.language = language.rawValue
    relabel = labelLanguage(language.rawValue)
  }
  return PreferencePress(next: next, relabel: relabel)
}
