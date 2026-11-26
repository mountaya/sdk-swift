/// LayersPanelHeading is what heads a section of a layers picker (`geo.layers.picker-rows`): a word
/// of the elements' `layers` section, by its path as `ElementsScope.word(_:)` reads one:
/// `layers.terrain` over the terrains, `layers.enrichment` over the enrichments, `layers.overlays`
/// over the classic overlays and `layers.time` over the time. A classic category's own name heads
/// no section: it names its segment of the overlays' category switch (`LayersPanelCategory`).
///
/// Two are equal where they read the same word, by its scalars.
public struct LayersPanelHeading: Sendable, Hashable {
  /// word is the path of the word that heads the section, its section and its key joined by a dot.
  public var word: String

  /// Creates the heading read as the word at `word`, `layers.terrain`.
  public init(word: String) {
    self.word = word
  }

  /// Two headings are equal where they read the same word, by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.word, rhs.word)
  }

  /// hash feeds the word.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(word)
  }
}
