/// DurationUnit is a unit a duration is stated in, each spelled by its contract unit id, the
/// ECMA-402 identifier. Each holds a fixed number of milliseconds, which a month and a year do
/// not, so neither is one.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum DurationUnit: String, CaseIterable, Sendable {
  /// day is a day of exactly 86,400 seconds.
  case day
  /// hour is an hour, 3,600 seconds.
  case hour
  /// millisecond is a thousandth of a second.
  case millisecond
  /// minute is a minute, 60 seconds.
  case minute
  /// second is the second.
  case second

  /// id is the contract's unit id, as `geo/units-convert.json` spells it.
  public var id: String { rawValue }
}
