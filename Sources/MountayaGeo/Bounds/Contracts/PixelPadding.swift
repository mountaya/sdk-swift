/// PixelPadding is a screen inset in pixels on each edge of a frame, the room a camera's fit
/// leaves between a box and the canvas's edges.
///
/// Two are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another than -0,
/// as every value of the geo layer compares, and equal values hash alike.
public struct PixelPadding: Sendable, Hashable {
  /// top is the inset at the top edge, toward the north, in pixels.
  public var top: Double
  /// right is the inset at the right edge, toward the east, in pixels.
  public var right: Double
  /// bottom is the inset at the bottom edge, toward the south, in pixels.
  public var bottom: Double
  /// left is the inset at the left edge, toward the west, in pixels.
  public var left: Double

  /// Creates a padding from the inset of each edge.
  public init(top: Double, right: Double, bottom: Double, left: Double) {
    self.top = top
    self.right = right
    self.bottom = bottom
    self.left = left
  }

  /// Creates a padding of one inset on every edge.
  public init(_ all: Double) {
    self.init(top: all, right: all, bottom: all, left: all)
  }

  /// Two paddings are equal where every edge is the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.top, rhs.top) && sameNumber(lhs.right, rhs.right)
      && sameNumber(lhs.bottom, rhs.bottom) && sameNumber(lhs.left, rhs.left)
  }

  /// hash feeds every edge as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: top)
    hasher.combine(sameNumber: right)
    hasher.combine(sameNumber: bottom)
    hasher.combine(sameNumber: left)
  }
}
