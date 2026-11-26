/// SectionChipCell is one figure a section chip states about its leg (`geo.profile.section-chips`):
/// which it is, and its value in meters or degrees.
///
/// Two are equal where they state one figure of the same number, as every value of the geo layer
/// compares.
public struct SectionChipCell: Sendable, Hashable {
  /// stat is the figure the cell states.
  public var stat: SectionChipStat
  /// value is its value, in meters or, for the grade, degrees.
  public var value: Double

  /// Creates a cell from its figure and its value.
  public init(stat: SectionChipStat, value: Double) {
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
