/// The seconds in a minute.
private let secondsPerMinute: Double = 60

/// parsePaceClock reads a pace typed as text back into decimal minutes, after trimming the white
/// space at its ends: `m:ss`, the minutes any number of digits and the seconds exactly two under
/// 60, so `13:20` is 13.333 and `4:05` is 4.083, or a bare number of minutes with a dot or a comma
/// before its decimals, so `13` is 13 and `6,5` is 6.5.
///
/// Anything else is nil: `13:5`, which could mean 5 seconds or 50, `13:60`, `1:02:03`, a sign,
/// text, and a pace of no time at all, such as `0:00`. Nil rather than a fallback, because a pace
/// the caller could not read must never silently become another one. The digits read are ASCII
/// digits alone, never another script's.
public func parsePaceClock(_ text: String) -> Double? {
  let scalars = Array(trimWhiteSpace(text).unicodeScalars)
  let minutes: Double
  if let colon = scalars.firstIndex(of: ":") {
    // A clock: whole minutes, a colon, and two digits of seconds under 60.
    let whole = scalars[..<colon]
    let seconds = scalars[(colon + 1)...]
    guard !whole.isEmpty, whole.allSatisfy(isAsciiDigit), seconds.count == 2,
      let tens = seconds.first, ("0"..."5").contains(tens), seconds.allSatisfy(isAsciiDigit),
      let wholeMinutes = Double(String(String.UnicodeScalarView(whole))),
      let secondCount = Double(String(String.UnicodeScalarView(seconds)))
    else { return nil }
    minutes = wholeMinutes + secondCount / secondsPerMinute
  } else {
    // A bare number of minutes, with a dot or a comma before its decimals.
    let mark = scalars.firstIndex { $0 == "." || $0 == "," }
    let whole = scalars[..<(mark ?? scalars.count)]
    let fraction = mark.map { scalars[($0 + 1)...] } ?? []
    guard !whole.isEmpty, whole.allSatisfy(isAsciiDigit),
      mark == nil || (!fraction.isEmpty && fraction.allSatisfy(isAsciiDigit))
    else { return nil }
    let spelled =
      String(String.UnicodeScalarView(whole)) + (mark == nil ? "" : ".")
      + String(String.UnicodeScalarView(fraction))
    guard let parsed = Double(spelled) else { return nil }
    minutes = parsed
  }
  return minutes.isFinite && minutes > 0 ? minutes : nil
}

/// Whether a scalar is an ASCII digit, `0` to `9`.
private func isAsciiDigit(_ scalar: Unicode.Scalar) -> Bool {
  ("0"..."9").contains(scalar)
}
