/// SpeedUnit is a unit a travel rate is stated in: a rate, a distance per time, or a pace, a time
/// per distance and the reciprocal of a rate. Each is spelled by its contract unit id, the
/// ECMA-402 identifier, and the wire carries every rate in `kilometerPerHour`.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum SpeedUnit: String, CaseIterable, Sendable {
  /// kilometerPerHour is kilometers per hour, a rate.
  case kilometerPerHour = "kilometer-per-hour"
  /// meterPerSecond is meters per second, a rate.
  case meterPerSecond = "meter-per-second"
  /// milePerHour is miles per hour, a rate.
  case milePerHour = "mile-per-hour"
  /// minutePerKilometer is minutes per kilometer, a pace in decimal minutes.
  case minutePerKilometer = "minute-per-kilometer"
  /// minutePerMile is minutes per mile, a pace in decimal minutes.
  case minutePerMile = "minute-per-mile"

  /// id is the contract's unit id, as `geo/units-convert.json` spells it.
  public var id: String { rawValue }
}
