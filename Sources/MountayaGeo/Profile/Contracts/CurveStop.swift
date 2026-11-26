/// CurveStop is one stop of the gradient a profile's curve is painted with (`geo.profile.curve-stops`):
/// where it stands, a fraction of the plot's width from 0 to 1, and its colour, or nil where no
/// stretch is coloured, which a renderer paints in its own accent.
///
/// Two are equal where they hold the same number and the colours are written alike, or absent on
/// both, as every value of the geo layer compares.
public struct CurveStop: Sendable, Hashable {
  /// offset is where the stop stands, from 0 at the plot's left edge to 1 at its right.
  public var offset: Double
  /// color is the stretch's colour, or nil for ground no stretch covers.
  public var color: String?

  /// Creates a stop from where it stands and its colour.
  public init(offset: Double, color: String?) {
    self.offset = offset
    self.color = color
  }

  /// Two stops are equal where they stand at the same number in colours written alike.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.offset, rhs.offset) && sameText(lhs.color, rhs.color)
  }

  /// hash feeds where it stands as the same-number relation reads it, then the colour.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: offset)
    hasher.combine(color)
  }
}
