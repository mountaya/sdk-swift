/// ProfileReadout is what a profile states about the sample its cursor stands on: the hover card,
/// and the readout a screen reader hears (`geo.profile.cursor-readout`), one reading so the two
/// never say different figures.
///
/// Two are equal where they state the same cells, the same grade and the same stretch, as every
/// value of the geo layer compares.
public struct ProfileReadout: Sendable, Hashable {
  /// cells is the figures asked for, in the order asked, each with a value.
  public var cells: [ReadoutCell]
  /// grade is the grade at the sample, in degrees, negative for a descent, nil where none reads.
  public var grade: Double?
  /// stretch is the classified stretch the sample stands in, which names it and colours it, nil in
  /// none.
  public var stretch: ProfileClass?

  /// Creates a readout from its cells, its grade and its stretch.
  public init(cells: [ReadoutCell], grade: Double?, stretch: ProfileClass?) {
    self.cells = cells
    self.grade = grade
    self.stretch = stretch
  }

  /// Two readouts are equal where every member is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.cells == rhs.cells && sameNumber(lhs.grade, rhs.grade) && lhs.stretch == rhs.stretch
  }

  /// hash feeds every member, the grade as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(cells)
    hasher.combine(sameNumber: grade)
    hasher.combine(stretch)
  }
}
