/// LayersPanelRow is one entry a layers picker lists, a terrain or an overlay
/// (`geo.layers.picker-rows`): its slug, its name in the reader's language, whether the selection
/// holds it, and the mark it shows.
///
/// Two are equal where they hold the same, a text by its scalars.
public struct LayersPanelRow: Sendable, Hashable {
  /// slug is the entry's slug, which a press hands on.
  public var slug: String
  /// label is the entry's name in the reader's language, else its English name, else its slug.
  public var label: String
  /// isChecked is whether the selection holds the entry.
  public var isChecked: Bool
  /// mark is what the row shows beside its label: its lock where the entry is out of the viewer's
  /// reach, a tick where the selection holds it, and nothing otherwise.
  public var mark: LayersPanelMark?

  /// Creates a row of the entry `slug`, labelled `label`.
  public init(slug: String, label: String, isChecked: Bool, mark: LayersPanelMark?) {
    self.slug = slug
    self.label = label
    self.isChecked = isChecked
    self.mark = mark
  }

  /// Two rows are equal where every member is the same, a text by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.slug, rhs.slug) && sameText(lhs.label, rhs.label)
      && lhs.isChecked == rhs.isChecked && lhs.mark == rhs.mark
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(slug)
    hasher.combine(label)
    hasher.combine(isChecked)
    hasher.combine(mark)
  }
}
