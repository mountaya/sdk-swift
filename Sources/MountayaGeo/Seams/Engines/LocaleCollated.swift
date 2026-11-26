import Foundation

/// localeCollated tells whether `first` sorts before `second` for a reader of `languageTag`,
/// collated by the platform's locale services in that locale, never the platform's default
/// (`platformLocale(_:)`): `sauna` between `Food` and `Water` in English, whatever their case.
func localeCollated(_ first: String, before second: String, languageTag: String) -> Bool {
  first.compare(second, options: [], range: nil, locale: platformLocale(languageTag))
    == .orderedAscending
}
