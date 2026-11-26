/// POIPanelGroup is one curated concept a points-of-interest picker offers as one row
/// (`geo.layers.poi-rows`), drawn by however many of the layers catalogue's keys it takes: water is
/// a spring, a drinking tap and a fountain.
///
/// A group is the app's data, not a published taxonomy: the label is the app's own words and the
/// keys are the catalogue's. Two are equal where they hold the same, a text by its scalars.
public struct POIPanelGroup: Sendable, Hashable {
  /// id is how the group is named to the app's own handler and among the groups it holds on.
  public var id: String
  /// label is the group's own label.
  public var label: String
  /// keys is the catalogue's keys the concept is drawn by. A row stands where any is drawn.
  public var keys: [String]
  /// glyph is the role of a glyph of the control set drawn beside the label, or nil for none.
  public var glyph: String?

  /// Creates a group `id`, labelled `label`, drawn by `keys`, with `glyph` beside its label.
  public init(id: String, label: String, keys: [String], glyph: String? = nil) {
    self.id = id
    self.label = label
    self.keys = keys
    self.glyph = glyph
  }

  /// Two groups are equal where every member is the same, a text by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && sameText(lhs.label, rhs.label)
      && lhs.keys.count == rhs.keys.count && zip(lhs.keys, rhs.keys).allSatisfy { sameText($0, $1) }
      && sameText(lhs.glyph, rhs.glyph)
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(label)
    hasher.combine(keys)
    hasher.combine(glyph)
  }
}
