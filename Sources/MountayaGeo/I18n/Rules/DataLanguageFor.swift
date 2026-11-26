import MountayaClient

/// dataLanguageFor turns a reader's language `tag` into the language the Data API answers a search
/// in, spelled as the API spells it: the language a map labels in for that tag
/// (`labelLanguage(_:)`), in capitals. So the answers a search returns and the labels on the map
/// beside it are one language for every tag: `fr-CH` asks in `FR`, `de_AT` in `DE`, and a tag
/// naming none of the map's languages, or no tag, asks in `EN`.
public func dataLanguageFor(_ tag: String?) -> DataSchema.Language {
  let language = labelLanguage(tag).rawValue.unicodeScalars.map { scalar in
    ("a"..."z").contains(scalar) ? Unicode.Scalar(scalar.value - 0x20) ?? scalar : scalar
  }
  return DataSchema.Language(rawValue: String(String.UnicodeScalarView(language)))
}
