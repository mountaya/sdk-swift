/// The seconds in a minute.
private let secondsPerMinute: Double = 60

/// The minutes in an hour.
private let minutesPerHour = 60

/// The first count a double holds that `Int` does not: 2^63.
private let intLimit: Double = 9_223_372_036_854_775_808

/// splitDuration splits a duration of `seconds` into the whole hours and the minutes a reader is
/// shown. The total is rounded to whole minutes first, a half minute rounding up, and then split,
/// so a remainder that rounds to sixty is carried into the hours: 7,170 s is 2 h 0 min, never 1 h
/// 60 min. Hours are not carried into days, so a day is 24 h.
///
/// A duration under thirty seconds splits into no hours and no minutes, a real duration too short
/// to state in minutes, which a surface renders as nothing. Nil for a missing, zero, negative or
/// non-finite duration, which is no duration at all. A count of minutes past the range of `Int` is
/// read as the greatest one.
public func splitDuration(_ seconds: Double?) -> DurationSplit? {
  guard let seconds, seconds.isFinite, seconds > 0 else { return nil }
  let rounded = roundHalfUp(seconds / secondsPerMinute)
  let minutes = rounded < intLimit ? Int(rounded) : Int.max
  return DurationSplit(hours: minutes / minutesPerHour, minutes: minutes % minutesPerHour)
}

/// roundHalfUp is a value of zero or more rounded to the nearest whole number, a half up. The
/// fraction is read exactly, so 0.49999999999999994 rounds down where adding a half first would
/// not.
func roundHalfUp(_ value: Double) -> Double {
  let whole = value.rounded(.down)
  return value - whole >= 0.5 ? whole + 1 : whole
}
