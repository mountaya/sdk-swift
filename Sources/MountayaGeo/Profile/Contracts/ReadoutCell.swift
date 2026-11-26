/// ReadoutCell is one figure a cursor readout states (`geo.profile.cursor-readout`): which it is,
/// and its value in meters.
///
/// Two are equal where they state one figure of the same number, as every value of the geo layer
/// compares.
public struct ReadoutCell: Sendable, Hashable {
  /// stat is the figure the cell states.
  public var stat: ReadoutStat
  /// value is its value, in meters.
  public var value: Double

  /// Creates a cell from its figure and its value.
  public init(stat: ReadoutStat, value: Double) {
    self.stat = stat
    self.value = value
  }

  /// Two cells are equal where they state one figure of the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.stat == rhs.stat && sameNumber(lhs.value, rhs.value)
  }

  /// hash feeds the figure, then the value as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(stat)
    hasher.combine(sameNumber: value)
  }
}
