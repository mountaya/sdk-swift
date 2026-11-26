/// ScreenRect is a rectangle on a map's screen, in logical pixels: where the watermark, a control
/// stack, a panel or a readout stands, measured from the top-left corner of the space it is laid
/// in, the map's unless its reader names another.
///
/// Two are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another than -0,
/// as every value of the geo layer compares, and equal values hash alike.
package struct ScreenRect: Sendable, Hashable {
  /// x and y are the top-left corner's distance from the space's left and top edges.
  package var x: Double
  package var y: Double
  /// width and height are the rectangle's size.
  package var width: Double
  package var height: Double

  /// Creates the rectangle whose top-left corner stands at `x` and `y`, `width` wide and `height`
  /// tall.
  package init(x: Double, y: Double, width: Double, height: Double) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }

  /// maxX is the right edge's distance from the space's left edge.
  package var maxX: Double { x + width }

  /// maxY is the bottom edge's distance from the space's top edge.
  package var maxY: Double { y + height }

  /// overlaps tells whether the two rectangles share any area: edges that only touch share none.
  package func overlaps(_ other: ScreenRect) -> Bool {
    x < other.maxX && other.x < maxX && y < other.maxY && other.y < maxY
  }

  /// offset answers the rectangle moved `dx` to the right and `dy` down.
  package func offset(dx: Double, dy: Double) -> ScreenRect {
    ScreenRect(x: x + dx, y: y + dy, width: width, height: height)
  }

  /// Two rectangles are equal where every number is the same.
  package static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.x, rhs.x) && sameNumber(lhs.y, rhs.y) && sameNumber(lhs.width, rhs.width)
      && sameNumber(lhs.height, rhs.height)
  }

  /// hash feeds every number as the same-number relation reads it.
  package func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: x)
    hasher.combine(sameNumber: y)
    hasher.combine(sameNumber: width)
    hasher.combine(sameNumber: height)
  }
}
