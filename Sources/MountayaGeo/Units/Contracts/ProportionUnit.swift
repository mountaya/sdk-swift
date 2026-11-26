/// ProportionUnit is a unit a proportion of a whole is stated in: the bare `ratio` a fraction is
/// computed as, where half reads 0.5, and the `percent` a reader reads, where it reads 50. A
/// gradient takes a `SlopeUnit` instead: a grade in degrees is no proportion of anything.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum ProportionUnit: String, CaseIterable, Sendable {
  /// percent is hundredths of the whole, ECMA-402's `percent`.
  case percent
  /// ratio is the bare number, the whole being one.
  case ratio

  /// id is the contract's unit id, as `geo/units-convert.json` spells it.
  public var id: String { rawValue }
}
