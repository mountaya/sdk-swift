/// AngleUnit is a unit an angle is stated in. `degree` is ECMA-402's identifier; `radian` is the
/// contract's own, since ECMA-402 lists none for it.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum AngleUnit: String, CaseIterable, Sendable {
  /// degree is a three hundred and sixtieth of a turn.
  case degree
  /// radian is the radian: a turn is two pi of them.
  case radian

  /// id is the contract's unit id, as `geo/units-convert.json` spells it.
  public var id: String { rawValue }
}
