/// SlopeUnit is a unit a gradient is stated in: the two a reader's slope preference names,
/// `degrees` and `percentage`, spelled as that preference's values, and the bare `ratio` of the
/// rise over the run, which is what geometry measures.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum SlopeUnit: String, CaseIterable, Sendable {
  /// degrees is the angle of the ground from the horizontal, in degrees.
  case degrees
  /// percentage is the grade: the ratio in hundredths, so forty-five degrees is a hundred percent.
  case percentage
  /// ratio is the rise over the run.
  case ratio

  /// id is the contract's unit id, as `geo/units-slope.json` spells it.
  public var id: String { rawValue }
}
