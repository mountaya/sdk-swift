import MountayaClient

/// ElementsScope is what every element under one scope reads (`geo.i18n.nested-scope`): the
/// language its words are in, the locale its figures are written in, the words themselves, resolved
/// for that language, and the two glyph sets, the one its controls draw with and the one the places
/// it marks are drawn with.
///
/// `standard` is the scope outside every statement: English, written in the locale `en`, with the
/// elements' own words and the bundled glyph sets. A nested scope is `scopeOf(_:stating:)` of the scope
/// around it and what it states, which is how SwiftUI's environment carries one into a view.
///
/// It has no public initializer, so a member the contract adds breaks no caller: a scope is
/// `standard`, or a scope nested in it. Two are equal where they hold the same, a text by its
/// scalars and the words as Geo compares JSON.
public struct ElementsScope: Sendable, Hashable {
  /// language is the language the scope's words are in.
  public let language: RestSchema.Language
  /// locale is the language tag a number, a date and a moment are written in, such as `fr-CH`.
  public let locale: String
  /// words is the scope's words, by section, resolved for `language` from the elements' own with
  /// the overrides folded on (`resolveBundle(_:language:overrides:handedOver:)`).
  public let words: [String: JSONValue]
  /// controlGlyphs is the glyph set the scope's controls draw with.
  public let controlGlyphs: GlyphSet
  /// markerGlyphs is the glyph set the places the scope's elements mark are drawn with.
  public let markerGlyphs: GlyphSet

  /// standard is the scope outside every statement: English, the locale `en`, the elements' own
  /// words, the bundled control set and the bundled marker set.
  public static let standard = ElementsScope(
    language: .en, locale: "en", words: resolveBundle(.elements), controlGlyphs: .control,
    markerGlyphs: .marker)

  /// Creates a scope of every setting it holds.
  init(
    language: RestSchema.Language, locale: String, words: [String: JSONValue],
    controlGlyphs: GlyphSet, markerGlyphs: GlyphSet
  ) {
    self.language = language
    self.locale = locale
    self.words = words
    self.controlGlyphs = controlGlyphs
    self.markerGlyphs = markerGlyphs
  }

  /// word is the word the scope reads at `path`, its section and its key joined by dots,
  /// `controls.zoomIn`: the scope's own where it is text, else the English word of the elements' own
  /// words, which hold every key, where an override left text out, and the path itself where
  /// neither holds text, so an element never draws a blank where a word belongs.
  public func word(_ path: String) -> String {
    text(at: path) ?? path
  }

  /// text is the word the scope reads at `path` as `word(_:)` reads it, nil where neither the
  /// scope's words nor the elements' own English words hold text there.
  func text(at path: String) -> String? {
    if case .string(let word)? = Self.value(at: path, in: words) {
      return word
    }
    if case .string(let word)? = Self.value(at: path, in: WordBundle.elements.english) {
      return word
    }
    return nil
  }

  /// The value `words` holds at a dotted path, or nil where it holds none there.
  private static func value(at path: String, in words: [String: JSONValue]) -> JSONValue? {
    var keys = path.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
    guard !keys.isEmpty else { return nil }
    let last = keys.removeLast()
    var section = words
    for key in keys {
      guard case .object(let inner)? = section[key] else { return nil }
      section = inner
    }
    return section[last]
  }

  /// Two scopes are equal where every setting is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.language, rhs.language) && sameText(lhs.locale, rhs.locale)
      && sameJson(lhs.words, rhs.words) && lhs.controlGlyphs == rhs.controlGlyphs
      && lhs.markerGlyphs == rhs.markerGlyphs
  }

  /// hash feeds every setting, the words as Geo compares JSON.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(language)
    hasher.combine(locale)
    hasher.combine(sameJson: words)
    hasher.combine(controlGlyphs)
    hasher.combine(markerGlyphs)
  }
}
