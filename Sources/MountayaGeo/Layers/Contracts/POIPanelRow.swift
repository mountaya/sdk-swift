/// POIPanelRow is one row a points-of-interest picker offers (`geo.layers.poi-rows`): a key of the
/// layers catalogue drawn at the points-of-interest rank, or a curated group of them, with the
/// drawn keys its toggle drives and whether it is on.
///
/// Two are equal where they hold the same, a text by its scalars.
public struct POIPanelRow: Sendable, Hashable {
  /// id is the catalogue's key, or the group's id.
  public var id: String
  /// label is a group's own label, a key's from the labels handed in, else the key itself.
  public var label: String
  /// glyph is the role of the glyph a group draws beside its label, or nil for none.
  public var glyph: String?
  /// keys is the drawn keys the row's toggle drives, and none that is not drawn.
  public var keys: [String]
  /// isVisible is whether the row is on: while any key it drives is shown, or, for a group the app
  /// holds the state of, while the app holds it on.
  public var isVisible: Bool

  /// Creates a row `id`, labelled `label`, driving `keys`, on where `isVisible` says so.
  public init(id: String, label: String, glyph: String? = nil, keys: [String], isVisible: Bool) {
    self.id = id
    self.label = label
    self.glyph = glyph
    self.keys = keys
    self.isVisible = isVisible
  }

  /// Two rows are equal where every member is the same, a text by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && sameText(lhs.label, rhs.label) && sameText(lhs.glyph, rhs.glyph)
      && lhs.keys.count == rhs.keys.count && zip(lhs.keys, rhs.keys).allSatisfy { sameText($0, $1) }
      && lhs.isVisible == rhs.isVisible
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(label)
    hasher.combine(glyph)
    hasher.combine(keys)
    hasher.combine(isVisible)
  }
}
