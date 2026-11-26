/// LayersPanelSection is one section of a layers picker (`geo.layers.picker-rows`): what heads it,
/// the choice its rows make, the catalogue category it lists, the classic categories its switch
/// offers, and its rows, in the catalogue's order.
///
/// Two are equal where they hold the same, a text by its scalars.
public struct LayersPanelSection: Sendable, Hashable {
  /// heading is what heads the section.
  public var heading: LayersPanelHeading
  /// choice is the choice the section's rows make.
  public var choice: LayersPanelChoice
  /// category is the slug of the catalogue category the section lists: the enrichment category's
  /// for the enrichments, the one the overlays open on for the classic overlays, and nil for the
  /// terrains and the time.
  public var category: String?
  /// rows is the section's entries, in the catalogue's order: the open category's for the classic
  /// overlays, and none for the time.
  public var rows: [LayersPanelRow]
  /// categories is the classic categories the overlays' switch offers, each holding an overlay, in
  /// the catalogue's order, a switch drawn where it lists two or more; none for every other
  /// section.
  public var categories: [LayersPanelCategory]

  /// Creates a section headed by `heading`, its `rows` making `choice` within `category`, its switch
  /// offering `categories`.
  public init(
    heading: LayersPanelHeading, choice: LayersPanelChoice, category: String?,
    rows: [LayersPanelRow], categories: [LayersPanelCategory] = []
  ) {
    self.heading = heading
    self.choice = choice
    self.category = category
    self.rows = rows
    self.categories = categories
  }

  /// Two sections are equal where every member is the same, a text by its scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.heading == rhs.heading && lhs.choice == rhs.choice
      && sameText(lhs.category, rhs.category) && lhs.rows == rhs.rows
      && lhs.categories == rhs.categories
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(heading)
    hasher.combine(choice)
    hasher.combine(category)
    hasher.combine(rows)
    hasher.combine(categories)
  }
}
