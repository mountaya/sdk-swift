/// PanelPlacement is where a panel a toggle opens stands over a map, and how it lays out there
/// (`geo.panels.layout`): its frame's top-left corner and its width, in logical pixels from the
/// map's top-left corner, and the layout its top inset gives it.
package struct PanelPlacement: Sendable, Hashable {
  /// x and y are the panel's top-left corner, from the map's.
  package let x: Double
  package let y: Double
  /// width is the panel's width: the layout's own, or the width a narrow map leaves it.
  package let width: Double
  /// layout is how the panel lays out with its top at `y`.
  package let layout: PanelLayout

  /// Creates the placement of a panel at `x` and `y`, `width` wide, laid out by `layout`.
  package init(x: Double, y: Double, width: Double, layout: PanelLayout) {
    self.x = x
    self.y = y
    self.width = width
    self.layout = layout
  }

  /// Two placements are equal where they stand at the same numbers and lay out alike.
  package static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.x, rhs.x) && sameNumber(lhs.y, rhs.y) && sameNumber(lhs.width, rhs.width)
      && lhs.layout == rhs.layout
  }

  /// hash feeds every number as the same-number relation reads it, and the layout.
  package func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: x)
    hasher.combine(sameNumber: y)
    hasher.combine(sameNumber: width)
    hasher.combine(layout)
  }
}
