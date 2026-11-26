/// AxisLabelBox is one place name laid out under a profile's distance axis
/// (`geo.profile.axis-label-culling`): its key and the left and right edges it takes, in whatever
/// unit the caller measured, the points of its own screen.
///
/// Two are equal where they hold the same key, written alike, and the same numbers, as every value
/// of the geo layer compares.
public struct AxisLabelBox: Sendable, Hashable {
  /// key names the name's place, `id#pass`.
  public var key: String
  /// left is where the name's left edge stands.
  public var left: Double
  /// right is where the name's right edge stands.
  public var right: Double

  /// Creates a box from its key and its two edges.
  public init(key: String, left: Double, right: Double) {
    self.key = key
    self.left = left
    self.right = right
  }

  /// Two boxes are equal where the keys are written alike and the edges are the same numbers.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && sameNumber(lhs.left, rhs.left)
      && sameNumber(lhs.right, rhs.right)
  }

  /// hash feeds the key, then both edges as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(sameNumber: left)
    hasher.combine(sameNumber: right)
  }
}
