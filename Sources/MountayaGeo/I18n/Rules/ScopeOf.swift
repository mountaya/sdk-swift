import MountayaClient

/// scopeOf is the scope nested in `outer` that states `statement` (`geo.i18n.nested-scope`).
///
/// **A setting stated is the scope's own, and one left out is the scope around it's.** The rule
/// reads the same at every depth, which is what lets a surface nest a scope of its own under its
/// host's and keep the host's language, words and glyph sets.
///
/// - **The words** are the scope around it's while the statement states no words and no language
///   other than the one around it, a language restating the one around it included. Otherwise they
///   resolve afresh from the language's base in the elements' own words, with the words the
///   statement states folded on, so words the scope around it states stay with that scope: an
///   override written for one language is that language's.
/// - **The locale** follows a language other than the one around it, read as its own tag, unless
///   the statement states a locale: a regional convention inherited across a change of language
///   is one nobody chose. A statement of the language around it keeps the locale it inherits.
/// - **The glyph sets** are inherited one by one, and a control set stated never stands in for the
///   marker set, since a control set holds no glyph for a place and would draw every one as the
///   same pin.
public func scopeOf(_ outer: ElementsScope, stating statement: ElementsScopeStatement)
  -> ElementsScope
{
  let language = statement.language ?? outer.language
  let changesLanguage = !sameText(language, outer.language)
  let inheritsWords = statement.words == nil && !changesLanguage
  return ElementsScope(
    language: language,
    locale: statement.locale ?? (changesLanguage ? language.rawValue : outer.locale),
    words: inheritsWords
      ? outer.words : resolveBundle(.elements, language: language, overrides: statement.words),
    controlGlyphs: statement.controlGlyphs ?? outer.controlGlyphs,
    markerGlyphs: statement.markerGlyphs ?? outer.markerGlyphs)
}
