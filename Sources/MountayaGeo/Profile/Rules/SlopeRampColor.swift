/// ascentSlopeRamp is the ramp an ascent paints from, in ascending degrees, the `ascentRampStops`
/// `geo/slope-ramp.json` declares: green to 2 degrees, then yellow, orange, red and a deep red from
/// 22 degrees. A renderer building a line gradient reads it as it is.
public let ascentSlopeRamp: [SlopeRampStop] = [
  SlopeRampStop(color: "#66BB6A", degrees: 0),
  SlopeRampStop(color: "#66BB6A", degrees: 2),
  SlopeRampStop(color: "#FFEB3B", degrees: 3),
  SlopeRampStop(color: "#FF9800", degrees: 6),
  SlopeRampStop(color: "#F44336", degrees: 11),
  SlopeRampStop(color: "#B71C1C", degrees: 22),
]

/// descentSlopeRamp is the ramp a descent paints from, by its magnitude, in ascending degrees, the
/// `descentRampStops` `geo/slope-ramp.json` declares: the green level ground shares with an ascent,
/// then blues that deepen to 22 degrees.
public let descentSlopeRamp: [SlopeRampStop] = [
  SlopeRampStop(color: "#66BB6A", degrees: 0),
  SlopeRampStop(color: "#64B5F6", degrees: 2),
  SlopeRampStop(color: "#29B6F6", degrees: 3),
  SlopeRampStop(color: "#1E88E5", degrees: 6),
  SlopeRampStop(color: "#1565C0", degrees: 11),
  SlopeRampStop(color: "#0D47A1", degrees: 22),
]

/// The colour a slope that is no number paints: a neutral grey, on no ramp.
private let unknownSlopeColor = "#94a3b8"

/// slopeRampColor is the colour a slope of `degrees` paints on a curve, `#rrggbb` in lower case. An
/// ascent reads `ascentSlopeRamp` and a descent `descentSlopeRamp` by its magnitude, and level
/// ground, either zero, the first ascent stop. Between two stops each channel is the straight mix
/// of theirs, rounded to the nearest whole number, a half up; at or past the last stop it is the
/// last colour. A slope that is not a number paints a neutral grey, `#94a3b8`.
public func slopeRampColor(_ degrees: Double) -> String {
  if degrees.isNaN { return unknownSlopeColor }
  if degrees > 0 { return asciiLowercase(rampColor(ascentSlopeRamp, at: degrees)) }
  if degrees < 0 { return asciiLowercase(rampColor(descentSlopeRamp, at: -degrees)) }
  return asciiLowercase(ascentSlopeRamp.first?.color ?? unknownSlopeColor)
}

/// The colour a ramp paints at a magnitude.
private func rampColor(_ stops: [SlopeRampStop], at magnitude: Double) -> String {
  guard let first = stops.first, let last = stops.last else { return unknownSlopeColor }
  if magnitude <= first.degrees { return first.color }
  if magnitude >= last.degrees { return last.color }
  for (lower, upper) in zip(stops, stops.dropFirst()) where magnitude <= upper.degrees {
    let span = upper.degrees - lower.degrees
    let ratio = span == 0 ? 0 : (magnitude - lower.degrees) / span
    return mixed(from: lower.color, to: upper.color, ratio: ratio)
  }
  return last.color
}

/// The colour `ratio` of the way from one colour to another, channel by channel, each written as
/// two lower-case hexadecimal digits.
private func mixed(from: String, to: String, ratio: Double) -> String {
  let start = channels(of: from)
  let end = channels(of: to)
  var text = "#"
  for channel in 0..<3 {
    let value = Double(start[channel]) + Double(end[channel] - start[channel]) * ratio
    let whole = value.rounded(.down)
    let rounded = value - whole >= 0.5 ? whole + 1 : whole
    let hex = String(Int(rounded), radix: 16)
    text += hex.count < 2 ? "0" + hex : hex
  }
  return text
}

/// The red, green and blue of a `#RRGGBB` colour, each 0 to 255; a channel that is no hexadecimal
/// pair reads 0.
private func channels(of color: String) -> [Int] {
  let scalars = Array(color.unicodeScalars.dropFirst())
  return (0..<3).map { channel in
    guard scalars.count >= 2 * channel + 2 else { return 0 }
    let pair = String(String.UnicodeScalarView(scalars[(2 * channel)..<(2 * channel + 2)]))
    return Int(pair, radix: 16) ?? 0
  }
}
