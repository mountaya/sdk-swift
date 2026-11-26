import MountayaClient

/// wordOverridesOf reads a consumer's override as JSON writes it, `words`, into its shape: keyed by
/// language where every key is a language a map labels in, spelled as the wire spells it (`fr`,
/// never `FR` or `fr-CA`), and keyed by section where none is. An empty override is keyed by
/// section and changes nothing.
///
/// Every one of the seven languages is a language key, never only the ones a bundle is translated
/// into: `{"de": {...}}` over a bundle with no German is German words, where read as sections it
/// would be a section named `de` folded onto English. No section of a bundle is named after a
/// language.
///
/// `nil`, the refusal, for an override naming a language and a section together: one key decides
/// the shape, so such an override's sections would be folded in no language. A language whose words
/// are not an object, `null` among them, is a language left out. No rule throws, so the refusal is
/// a classification.
public func wordOverridesOf(_ words: [String: JSONValue]) -> WordOverrides? {
  let languages = Dictionary(uniqueKeysWithValues: labelLanguages.map { ($0.rawValue, $0) })
  let named = words.keys.filter { languages[$0] != nil }.count
  switch named {
  case 0:
    return .bySection(words)
  case words.count:
    var byLanguage: [RestSchema.Language: [String: JSONValue]] = [:]
    for (key, value) in words {
      if let language = languages[key], case .object(let members) = value {
        byLanguage[language] = members
      }
    }
    return .byLanguage(byLanguage)
  default:
    return nil
  }
}
