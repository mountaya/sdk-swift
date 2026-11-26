// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// Localized text for a tile legend, keyed by language code. Each language maps
  /// to a set of named strings (see LocaleMap); a language is null when no
  /// translation is provided for it.
  public struct Locales: Sendable, Hashable, Codable {
    /// The German strings for this legend. Null when the legend carries no German
    /// translation, which is the case a client falls back from rather than
    /// renders.
    public var de: TileSchema.LocaleMap?
    /// The English strings for this legend. Null when the legend carries no
    /// English translation, which is the case a client falls back from rather
    /// than renders.
    public var en: TileSchema.LocaleMap?
    /// The Spanish strings for this legend. Null when the legend carries no
    /// Spanish translation, which is the case a client falls back from rather
    /// than renders.
    public var es: TileSchema.LocaleMap?
    /// The French strings for this legend. Null when the legend carries no French
    /// translation, which is the case a client falls back from rather than
    /// renders.
    public var fr: TileSchema.LocaleMap?
    /// The Italian strings for this legend. Null when the legend carries no
    /// Italian translation, which is the case a client falls back from rather
    /// than renders.
    public var it: TileSchema.LocaleMap?
    /// The Japanese strings for this legend. Null when the legend carries no
    /// Japanese translation, which is the case a client falls back from rather
    /// than renders.
    public var ja: TileSchema.LocaleMap?
    /// The Chinese strings for this legend. Null when the legend carries no
    /// Chinese translation, which is the case a client falls back from rather
    /// than renders.
    public var zh: TileSchema.LocaleMap?

    /// Creates a `Locales` from the properties the contract requires, the optional ones being set
    /// in `configure`.
    public init(
      de: TileSchema.LocaleMap?,
      en: TileSchema.LocaleMap?,
      es: TileSchema.LocaleMap?,
      fr: TileSchema.LocaleMap?,
      it: TileSchema.LocaleMap?,
      ja: TileSchema.LocaleMap?,
      zh: TileSchema.LocaleMap?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.de = de
      self.en = en
      self.es = es
      self.fr = fr
      self.it = it
      self.ja = ja
      self.zh = zh
      configure(&self)
    }

    /// Reads a `Locales` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.de = try container.decodeIfPresent(TileSchema.LocaleMap.self, forKey: "de")
      self.en = try container.decodeIfPresent(TileSchema.LocaleMap.self, forKey: "en")
      self.es = try container.decodeIfPresent(TileSchema.LocaleMap.self, forKey: "es")
      self.fr = try container.decodeIfPresent(TileSchema.LocaleMap.self, forKey: "fr")
      self.it = try container.decodeIfPresent(TileSchema.LocaleMap.self, forKey: "it")
      self.ja = try container.decodeIfPresent(TileSchema.LocaleMap.self, forKey: "ja")
      self.zh = try container.decodeIfPresent(TileSchema.LocaleMap.self, forKey: "zh")
    }

    /// Writes a `Locales` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeNullable(self.de, forKey: "de")
      try container.encodeNullable(self.en, forKey: "en")
      try container.encodeNullable(self.es, forKey: "es")
      try container.encodeNullable(self.fr, forKey: "fr")
      try container.encodeNullable(self.it, forKey: "it")
      try container.encodeNullable(self.ja, forKey: "ja")
      try container.encodeNullable(self.zh, forKey: "zh")
    }
  }
}
