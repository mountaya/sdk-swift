/// DistanceTick is one labelled stop of a distance axis: its value in the reader's distance unit,
/// its position in meters, and the fraction digits its label needs for neighbouring stops to read
/// as different numbers.
///
/// Two are equal where they hold the same numbers, as every value of the geo layer compares.
public struct DistanceTick: Sendable, Hashable {
  /// value is the stop in the display unit, kilometers or miles, on the 1, 2, 5 lattice.
  public var value: Double
  /// meters is the stop in meters from the itinerary's start, where a chart places it.
  public var meters: Double
  /// fractionDigits is the fraction digits the label is written with, never under 0.
  public var fractionDigits: Int

  /// Creates a stop from its value, its position and its label's fraction digits.
  public init(value: Double, meters: Double, fractionDigits: Int) {
    self.value = value
    self.meters = meters
    self.fractionDigits = fractionDigits
  }

  /// Two stops are equal where both numbers are the same numbers and the digits one count.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.value, rhs.value) && sameNumber(lhs.meters, rhs.meters)
      && lhs.fractionDigits == rhs.fractionDigits
  }

  /// hash feeds both numbers as the same-number relation reads them, then the digits.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: value)
    hasher.combine(sameNumber: meters)
    hasher.combine(fractionDigits)
  }
}
