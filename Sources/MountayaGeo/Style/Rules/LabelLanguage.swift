import MountayaClient

/// labelLanguages are the languages a map labels in, the ones the contract's `Locales` is keyed by,
/// each a `name:{language}` field of the base map's tiles: English, French, Spanish, Italian,
/// German, Chinese and Japanese, English first as the one a tag naming none of them reads.
public let labelLanguages: [RestSchema.Language] = [
  .en, .fr, .es, .it, .de, .zh, .ja,
]

/// labelLanguage reads the language a map labels in from a language `tag`: its primary subtag, the
/// run before the first hyphen or underscore, compared whole and with the ASCII capitals folded
/// against `labelLanguages`. So `fr-CA`, `fr_CA` and `FR` label in French and `zh-Hant-TW` in
/// Chinese, while `frr` (North Frisian, compared whole and never as a prefix), `pt-BR`, `und-FR`,
/// `*`, the empty tag and no tag at all label in English.
///
/// An underscore parts subtags as a hyphen does, which is how the API reads the `Accept-Language`
/// header it answers in, so a map's labels and the words the API answers in are one language. Only
/// the ASCII letters are folded, the only ones a language subtag is written in, so a dotted capital
/// I folds to no `i`. Nothing is trimmed: ` fr` labels in English.
public func labelLanguage(_ tag: String?) -> RestSchema.Language {
  guard let tag else { return .en }
  let primary = asciiLowercase(String(tag.unicodeScalars.prefix { $0 != "-" && $0 != "_" }))
  return labelLanguages.first { $0.rawValue == primary } ?? .en
}
