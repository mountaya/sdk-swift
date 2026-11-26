/// LengthUnit is a unit a length is stated in, each spelled by its contract unit id, which is the
/// ECMA-402 identifier, so a length converted into one formats under the same id.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum LengthUnit: String, CaseIterable, Sendable {
  /// centimeter is a hundredth of a meter.
  case centimeter
  /// foot is the international foot, exactly 0.3048 m: twelve inches.
  case foot
  /// inch is the international inch, exactly 2.54 cm.
  case inch
  /// kilometer is a thousand meters.
  case kilometer
  /// meter is the meter, the unit the wire carries every length in.
  case meter
  /// mile is the international mile, exactly 1,609.344 m: 5,280 feet.
  case mile

  /// id is the contract's unit id, as `geo/units-convert.json` spells it.
  public var id: String { rawValue }
}
