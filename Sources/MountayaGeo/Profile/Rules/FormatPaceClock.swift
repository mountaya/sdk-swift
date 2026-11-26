/// The seconds in a minute.
private let secondsPerMinute: Double = 60

/// The first count of seconds a double holds no longer to the second: 2^53.
private let exactSecondsLimit: Double = 9_007_199_254_740_992

/// formatPaceClock writes a pace of `minutes`, decimal minutes per unit of distance, as the `m:ss`
/// clock a reader reads it in: 13.333 minutes is `13:20`. The pace is rounded to whole seconds
/// before it is split, so a remainder never reads 60: 13.999 minutes is `14:00`. The minutes are
/// never capped, so a 1 km/h rate is `60:00` a kilometer.
///
/// The clock is the pace's own notation, the same in every language: the digits are Latin, and the
/// seconds always two of them. The empty string for a pace that is missing, no positive finite
/// number, or one that rounds to no second, since `0:00` states a pace of no time at all, and for
/// one of 2^53 seconds or more, which no longer counts to the second.
public func formatPaceClock(_ minutes: Double?) -> String {
  guard let seconds = clockSeconds(minutes) else { return "" }
  let remainder = seconds % 60
  return "\(seconds / 60):\(remainder < 10 ? "0" : "")\(remainder)"
}

/// clockSeconds is the whole seconds a pace of `minutes` reads as, a half second up, or nil where
/// it is missing, no positive finite number, rounds to no second, or is so long that a double no
/// longer counts it to the second.
func clockSeconds(_ minutes: Double?) -> Int? {
  guard let minutes, minutes.isFinite, minutes > 0 else { return nil }
  let seconds = roundHalfUp(minutes * secondsPerMinute)
  return seconds > 0 && seconds < exactSecondsLimit ? Int(seconds) : nil
}
