/// fallbackLanguage is the language a locale that is no language tag is read in.
let fallbackLanguage = "en"

/// languageTagOf is a locale as the language tag a platform's locale services are handed: an
/// underscore parts two subtags as a hyphen does, which is how a platform spells a locale and how
/// the API reads the `Accept-Language` header it answers in, and a value that is no language tag,
/// the empty string included, reads as `fallbackLanguage`. The locale is always an argument, never
/// the platform's default.
///
/// A language tag is a language of two to eight ASCII letters, then subtags of one to eight ASCII
/// letters or digits, each after a hyphen.
func languageTagOf(_ locale: String) -> String {
  let hyphenated = String(
    String.UnicodeScalarView(locale.unicodeScalars.map { $0 == "_" ? "-" : $0 }))
  return isLanguageTag(hyphenated) ? hyphenated : fallbackLanguage
}

/// primaryLanguageOf is the primary language subtag of a locale in lower case: `fr` for `fr-CA`
/// and for `FR_ca`, read as `languageTagOf(_:)` reads the locale.
func primaryLanguageOf(_ locale: String) -> String {
  let tag = languageTagOf(locale)
  return asciiLowercase(String(String.UnicodeScalarView(tag.unicodeScalars.prefix { $0 != "-" })))
}

/// isLanguageTag tells whether a text is a well-formed tag: two to eight ASCII letters, then any
/// number of subtags of one to eight ASCII letters or digits, each after a hyphen.
private func isLanguageTag(_ text: String) -> Bool {
  let subtags = text.unicodeScalars.split(separator: "-", omittingEmptySubsequences: false)
  guard let language = subtags.first, (2...8).contains(language.count),
    language.allSatisfy(isAsciiLetter)
  else { return false }
  return subtags.dropFirst().allSatisfy { subtag in
    (1...8).contains(subtag.count) && subtag.allSatisfy { isAsciiLetter($0) || isAsciiDigit($0) }
  }
}

private func isAsciiLetter(_ scalar: Unicode.Scalar) -> Bool {
  ("A"..."Z").contains(scalar) || ("a"..."z").contains(scalar)
}

private func isAsciiDigit(_ scalar: Unicode.Scalar) -> Bool {
  ("0"..."9").contains(scalar)
}
