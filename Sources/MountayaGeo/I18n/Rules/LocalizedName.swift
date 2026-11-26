import MountayaClient

/// The member of a language's strings that holds an entry's display name.
private let nameKey = "name"

/// localizedName is the display name of a catalogue entry (an activity, a category, an overlay, a
/// terrain) whose names per language are `locales` and whose identifier is `slug`, for a reader of
/// `language`: its name in that language, else its English name, else its slug.
///
/// The language is read as a label language is, by its primary subtag (`labelLanguage(_:)`), so
/// `fr-CA` and `FR` read French and a language the catalogue is not keyed by reads English. A name
/// that is the empty string falls through as a missing one does, since the wire's name may carry
/// one; a name of white space is a name. The slug is the last answer, so a picker in a language
/// nobody translated the catalogue into still says what each entry is.
public func localizedName(locales: RestSchema.Locales, slug: String, language: String?) -> String {
  firstNamed(
    names(of: localeMap(of: locales, for: labelLanguage(language))), names(of: locales.en)) ?? slug
}

/// localizedName is the display name of an entry of the Tile API's layers manifest, whose names
/// per language are `locales`, as the REST API's entries are named: its name in `language`, else
/// in English, else `slug`.
public func localizedName(locales: TileSchema.Locales, slug: String, language: String?) -> String {
  firstNamed(
    names(of: localeMap(of: locales, for: labelLanguage(language))), names(of: locales.en)) ?? slug
}

/// The name a language's strings hold, or `nil` where they hold none.
private func names(of strings: [String: String?]?) -> String? {
  strings?[nameKey] ?? nil
}

/// The first of `names` that is a name, neither missing nor empty.
private func firstNamed(_ names: String?...) -> String? {
  names.lazy.compactMap { $0 }.first { !$0.isEmpty }
}

/// The strings `locales` holds for `language`, one of the seven it is keyed by.
private func localeMap(of locales: RestSchema.Locales, for language: RestSchema.Language)
  -> RestSchema.LocaleMap?
{
  switch language {
  case .de: return locales.de
  case .es: return locales.es
  case .fr: return locales.fr
  case .it: return locales.it
  case .ja: return locales.ja
  case .zh: return locales.zh
  default: return locales.en
  }
}

/// The strings the Tile API's `locales` holds for `language`, one of the seven it is keyed by.
private func localeMap(of locales: TileSchema.Locales, for language: RestSchema.Language)
  -> TileSchema.LocaleMap?
{
  switch language {
  case .de: return locales.de
  case .es: return locales.es
  case .fr: return locales.fr
  case .it: return locales.it
  case .ja: return locales.ja
  case .zh: return locales.zh
  default: return locales.en
  }
}
