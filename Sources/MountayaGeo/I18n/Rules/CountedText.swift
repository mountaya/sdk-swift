import MountayaClient

/// countedText writes the counted word `word` for `count` (`geo.i18n.counted-words`): the form its
/// language names for the count, with the count in place of its `{count}` placeholder.
///
/// A counted word is what the elements' words table writes for a word that counts, an object of
/// the forms CLDR's plural rules name, `{"one": "{count} result", "other": "{count} results"}`. The
/// form is the language's: in French the `one` form for zero and one, and in English, as in every
/// language the table does not hold, the `one` form for one; any other count, and a count whose
/// form the word does not state, takes the `other` form.
///
/// The count is written by the platform's locale services in `language`, its digits and its
/// grouping that language's, never digits assembled by hand: 1234 is `1,234` in English and
/// `1 234` in French, grouped by a narrow no-break space, U+202F (`formatNumber(_:locale:)`). The
/// first `{count}` a form holds takes it, read scalar by scalar, and a form that holds none is
/// written as it is.
///
/// `nil` where `word` is no counted word, an object holding no `other` form that is text: no rule
/// of the geo layer throws, so the refusal is an answer.
public func countedText(_ word: JSONValue, count: Int, language: RestSchema.Language) -> String? {
  guard case .object(let forms) = word, case .string(let other)? = forms["other"] else {
    return nil
  }
  let isOne = sameText(language, .fr) ? count == 0 || count == 1 : count == 1
  var form = other
  if isOne, case .string(let one)? = forms["one"] {
    form = one
  }
  guard let placeholder = firstPlaceholder(in: form, named: "count") else { return form }
  let written = formatNumber(Double(count), locale: language.rawValue, maximumFractionDigits: 0)
  form.replaceSubrange(placeholder, with: written)
  return form
}
