/// LayersPanelCategory is one classic category a layers picker's overlays section switches between
/// (`geo.layers.picker-rows`): its slug, which a pick in the switch hands back, and its name in the
/// reader's language.
///
/// Two are equal where they hold the same, a text by its scalars.
public struct LayersPanelCategory: Sendable, Hashable {
  /// slug is the category's slug, as the catalogue spells it.
  public var slug: String
  /// name is the category's name in the reader's language, else in English, else its slug.
  public var name: String

  /// Creates the category `slug` names, called `name`.
  public init(slug: String, name: String) {
    self.slug = slug
    self.name = name
  }

  /// Two categories are equal where their slugs and their names are the same, by their scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.slug, rhs.slug) && sameText(lhs.name, rhs.name)
  }

  /// hash feeds both members.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(slug)
    hasher.combine(name)
  }
}
