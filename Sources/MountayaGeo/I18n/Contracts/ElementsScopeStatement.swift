import MountayaClient

/// ElementsScopeStatement is what a nested elements scope states (`geo.i18n.nested-scope`): every
/// member optional, and one it leaves nil is the scope around it's (`scopeOf(_:stating:)`).
///
/// Two are equal where they state the same, a text by its scalars.
public struct ElementsScopeStatement: Sendable, Hashable {
  /// language is the language the scope's words are in, or nil for the scope around it's.
  public var language: RestSchema.Language?
  /// locale is the language tag the scope's figures are written in, such as `fr-CH`, or nil for the
  /// one its language reads in: the scope around it's, or a language it states in its place.
  public var locale: String?
  /// words is the scope's own words, keyed by section or by language as a bundle's overrides are,
  /// or nil for none of its own.
  public var words: WordOverrides?
  /// controlGlyphs is the glyph set the scope's controls draw with, or nil for the scope around
  /// it's. It never stands in for the marker set.
  public var controlGlyphs: GlyphSet?
  /// markerGlyphs is the glyph set the places the scope's elements mark are drawn with, or nil for
  /// the scope around it's.
  public var markerGlyphs: GlyphSet?

  /// Creates a statement of the settings given, every other one the scope around it's.
  public init(
    language: RestSchema.Language? = nil, locale: String? = nil, words: WordOverrides? = nil,
    controlGlyphs: GlyphSet? = nil, markerGlyphs: GlyphSet? = nil
  ) {
    self.language = language
    self.locale = locale
    self.words = words
    self.controlGlyphs = controlGlyphs
    self.markerGlyphs = markerGlyphs
  }

  /// Two statements are equal where they state the same settings.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.language?.rawValue, rhs.language?.rawValue) && sameText(lhs.locale, rhs.locale)
      && lhs.words == rhs.words && lhs.controlGlyphs == rhs.controlGlyphs
      && lhs.markerGlyphs == rhs.markerGlyphs
  }

  /// hash feeds every setting stated.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(language)
    hasher.combine(locale)
    hasher.combine(words)
    hasher.combine(controlGlyphs)
    hasher.combine(markerGlyphs)
  }
}
