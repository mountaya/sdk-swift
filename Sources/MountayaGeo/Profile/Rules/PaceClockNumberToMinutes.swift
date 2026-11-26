/// The hundredths a clock number carries its seconds in.
private let hundredths: Double = 100

/// The seconds in a minute.
private let secondsPerMinute: Double = 60

/// paceClockNumberToMinutes reads an `m.ss` clock number, the whole minutes plus the seconds over
/// 100, back into decimal minutes: 13.2 is 13 minutes 20 seconds, 13.333 minutes. Its hundredths
/// are read as whole seconds, rounded, and seconds past 59 carry into the minutes, since a numeric
/// input steps in decimal: `13:55` plus five seconds arrives as 13.6, fourteen minutes flat.
///
/// Nil for a value that is missing or no positive finite number.
public func paceClockNumberToMinutes(_ value: Double?) -> Double? {
  guard let value, value.isFinite, value > 0 else { return nil }
  let minutes = value.rounded(.down)
  return minutes + roundHalfUp((value - minutes) * hundredths) / secondsPerMinute
}
