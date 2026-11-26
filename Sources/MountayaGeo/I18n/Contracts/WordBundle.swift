import MountayaClient

/// WordBundle is the words a surface reads, as the tree a bundle's JSON writes them: a word is a
/// string leaf, and a section an object of words and sections. A typed set of words is decoded from
/// the tree a bundle resolves to, so one fold serves every surface's words.
///
/// `english` is the words every language falls back to, so a bundle always holds them.
/// `translations` are the other languages the bundle carries, each a whole set of words, and
/// `partial` the languages it carries only some words for, each folded over the language's base. A
/// translation keyed English stands ahead of `english`, as a translation of any language stands
/// ahead of the fallback.
///
/// Two are equal where they hold the same words, each compared as Geo compares JSON, a number by
/// the same-number relation, a text by its scalars and an object's members in any order, and equal
/// bundles hash alike.
public struct WordBundle: Sendable, Hashable {
  /// english is the English words, the base of every language with no translation of its own.
  public var english: [String: JSONValue]
  /// translations are the translations the bundle carries, keyed by language.
  public var translations: [RestSchema.Language: [String: JSONValue]]
  /// partial is the words the bundle carries for a language beside its base, keyed by language.
  public var partial: [RestSchema.Language: [String: JSONValue]]

  /// Creates a bundle from its English words, the translations it carries and its partial layers.
  public init(
    english: [String: JSONValue],
    translations: [RestSchema.Language: [String: JSONValue]] = [:],
    partial: [RestSchema.Language: [String: JSONValue]] = [:]
  ) {
    self.english = english
    self.translations = translations
    self.partial = partial
  }

  /// Two bundles are equal where every set of words they hold is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameJson(lhs.english, rhs.english) && sameWords(lhs.translations, rhs.translations)
      && sameWords(lhs.partial, rhs.partial)
  }

  /// hash feeds every set of words as Geo compares JSON.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameJson: english)
    hasher.combine(sameWords: translations)
    hasher.combine(sameWords: partial)
  }
}

/// sameWords tells whether two sets of words keyed by language hold the same languages, each with
/// the same words.
func sameWords(
  _ a: [RestSchema.Language: [String: JSONValue]], _ b: [RestSchema.Language: [String: JSONValue]]
) -> Bool {
  a.count == b.count
    && a.allSatisfy { language, words in b[language].map { sameJson(words, $0) } ?? false }
}

extension Hasher {
  /// Feeds a set of words keyed by language, its languages in no order.
  mutating func combine(sameWords words: [RestSchema.Language: [String: JSONValue]]) {
    var commutative = 0
    for (language, members) in words {
      var member = Hasher()
      member.combine(language)
      member.combine(sameJson: members)
      commutative ^= member.finalize()
    }
    combine(words.count)
    combine(commutative)
  }
}
