import MountayaClient

/// The measurement systems in the order the contract lists them, each with the key of its word.
private let lengthOptions: [(RestSchema.UnitLength, String)] = [
  (.metric, "metric"), (.imperial, "imperial"),
]

/// The forms a travel rate takes in the order the contract lists them, each with its word's key.
private let paceOptions: [(RestSchema.UnitPace, String)] = [
  (.perTime, "perTime"), (.perDistance, "perDistance"),
]

/// The slope notations in the order the contract lists them, each with the key of its word.
private let slopeOptions: [(RestSchema.UnitSlope, String)] = [
  (.degrees, "degrees"), (.percentage, "percentage"),
]

/// The temperature scales in the order the contract lists them, each with the key of its word.
private let temperatureOptions: [(RestSchema.UnitTemperature, String)] = [
  (.celsius, "celsius"), (.fahrenheit, "fahrenheit"),
]

/// preferenceChoices is what a preferences picker offers over `preferences`
/// (`geo.units.preference-choices`): the length system, the form a travel rate takes, the slope
/// notation, the temperature scale and the label language, in that order, each option in the order
/// the contract lists it, a unit labelled by its word of the elements' `preferences` section and a
/// language by its own name.
///
/// An option is checked where the set holds it, a unit spelled with the same scalars, and a
/// language as the map reads one, by its primary subtag (`labelLanguage(_:)`): a set holding
/// `fr-CA` checks French, and one holding a tag the map labels in no language of, `pt-BR`, checks
/// English. A unit the set holds that the contract does not list checks none of its options.
public func preferenceChoices(_ preferences: UnitPreferences) -> [PreferenceChoice] {
  let language = labelLanguage(preferences.language)
  return [
    PreferenceChoice(
      field: .length,
      options: lengthOptions.map { value, word in
        unitOption(.length(value), word: word, isChecked: sameText(value, preferences.length))
      }),
    PreferenceChoice(
      field: .pace,
      options: paceOptions.map { value, word in
        unitOption(.pace(value), word: word, isChecked: sameText(value, preferences.pace))
      }),
    PreferenceChoice(
      field: .slope,
      options: slopeOptions.map { value, word in
        unitOption(.slope(value), word: word, isChecked: sameText(value, preferences.slope))
      }),
    PreferenceChoice(
      field: .temperature,
      options: temperatureOptions.map { value, word in
        unitOption(
          .temperature(value), word: word, isChecked: sameText(value, preferences.temperature))
      }),
    PreferenceChoice(
      field: .language,
      options: labelLanguages.map { value in
        PreferenceOption(
          value: .language(value), label: .name(languageEndonyms[value] ?? value.rawValue),
          isChecked: sameText(value, language))
      }),
  ]
}

/// The option of a unit, labelled by its word.
private func unitOption(_ value: PreferenceValue, word: String, isChecked: Bool)
  -> PreferenceOption
{
  PreferenceOption(value: value, label: .word(word), isChecked: isChecked)
}
