/// The hundredths a clock number carries its seconds in.
private let hundredths: Double = 100

/// paceMinutesToClockNumber writes a pace of `minutes`, decimal minutes, as the `m.ss` number a
/// clock-separated numeric input carries: the whole minutes plus the seconds over 100, so 13.333
/// minutes, the clock `13:20`, is 13.2. The seconds are the ones `formatPaceClock(_:)` states,
/// rounded before the split, so 13.999 minutes is 14.
///
/// The number is positional, never linear: 13.2 is thirteen minutes twenty, not thirteen and a
/// fifth, so it never leaves the input it is shown in. Nil where `formatPaceClock(_:)` states
/// nothing.
public func paceMinutesToClockNumber(_ minutes: Double?) -> Double? {
  guard let seconds = clockSeconds(minutes) else { return nil }
  return Double(seconds / 60) + Double(seconds % 60) / hundredths
}
