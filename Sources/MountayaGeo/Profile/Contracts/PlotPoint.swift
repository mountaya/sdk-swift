/// PlotPoint is a point of a profile's plot, in the 100-unit square it is drawn in, which is also a
/// percentage of the box the square is stretched into: `x` from the window's start at 0 to its end
/// at 100, and `y` down from the top (`geo.profile.plot-scale`).
///
/// Two are equal where they hold the same numbers, as every value of the geo layer compares.
public struct PlotPoint: Sendable, Hashable {
  /// x is how far across the plot the point stands.
  public var x: Double
  /// y is how far down the plot the point stands.
  public var y: Double

  /// Creates a point from where it stands across and down the plot.
  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }

  /// Two points are equal where both numbers are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.x, rhs.x) && sameNumber(lhs.y, rhs.y)
  }

  /// hash feeds both numbers as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: x)
    hasher.combine(sameNumber: y)
  }
}
