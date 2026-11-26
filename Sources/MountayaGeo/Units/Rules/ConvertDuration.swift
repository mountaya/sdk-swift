/// convertDuration converts a value from one duration unit to another through the whole number
/// of milliseconds each holds, a day being 86,400 s. Nothing is clamped, and a value that is not
/// finite converts to itself.
public func convertDuration(_ value: Double, from: DurationUnit, to: DurationUnit) -> Double {
  scaleByRatio(value, numerator: from.milliseconds, denominator: to.milliseconds)
}

extension DurationUnit {
  /// milliseconds is the unit's length in whole milliseconds.
  var milliseconds: Int64 {
    let second: Int64 = 1_000
    let minute = 60 * second
    let hour = 60 * minute
    switch self {
    case .day: return 24 * hour
    case .hour: return hour
    case .millisecond: return 1
    case .minute: return minute
    case .second: return second
    }
  }
}
