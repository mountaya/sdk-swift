/// SlopeRampStop is one stop of a slope ramp: the colour a slope of `degrees` paints, and the
/// slopes between two stops paint the colour between theirs.
///
/// Two are equal where they hold the same colour and the same number, as every value of the geo
/// layer compares.
public struct SlopeRampStop: Sendable, Hashable {
  /// color is the colour, `#RRGGBB`.
  public var color: String
  /// degrees is the slope's magnitude, in degrees: each half of a ramp is read by magnitude.
  public var degrees: Double

  /// Creates a stop from its colour and its slope.
  public init(color: String, degrees: Double) {
    self.color = color
    self.degrees = degrees
  }

  /// Two stops are equal where the colour is one and the slope the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.color, rhs.color) && sameNumber(lhs.degrees, rhs.degrees)
  }

  /// hash feeds the colour, then the slope as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(color)
    hasher.combine(sameNumber: degrees)
  }
}
