import MountayaClient

/// WordOverrides is a consumer's own words, folded over a bundle's last: keyed by section, for
/// whichever language is selected, or keyed by language, for that language alone. It is one shape
/// or the other, never both, so an override read from JSON is classified by `wordOverridesOf(_:)`,
/// which refuses one naming a language and a section together.
///
/// Two are equal where they are the same shape and hold the same words.
public enum WordOverrides: Sendable, Hashable {
  /// bySection is words for the selected language, keyed by section as the bundle's are.
  case bySection([String: JSONValue])
  /// byLanguage is words per language, each language's sections under it.
  case byLanguage([RestSchema.Language: [String: JSONValue]])

  /// Two overrides are equal where they are of one shape and hold the same words.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.bySection(let left), .bySection(let right)):
      return sameJson(left, right)
    case (.byLanguage(let left), .byLanguage(let right)):
      return sameWords(left, right)
    default:
      return false
    }
  }

  /// hash feeds the shape and the words as Geo compares JSON.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .bySection(let words):
      hasher.combine(0)
      hasher.combine(sameJson: words)
    case .byLanguage(let words):
      hasher.combine(1)
      hasher.combine(sameWords: words)
    }
  }
}
