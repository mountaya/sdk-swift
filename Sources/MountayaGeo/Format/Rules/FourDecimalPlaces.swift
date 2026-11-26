/// fourDecimalPlaces writes a magnitude, a finite number of zero or more, with four decimal places
/// in Latin digits and a full stop: its binary value rounded half away from zero, exactly, by
/// integer arithmetic rather than by a platform formatter. A value exactly halfway between two
/// places, such as 0.03125, takes the larger.
///
/// The digits come from no formatter because a formatter's rounding and digits are the platform's
/// to choose, and Foundation's on Linux and on Darwin are two implementations: a figure a reader
/// sees has to read alike in every SDK and on every host. Every finite magnitude is written in
/// full, however large, never with an exponent.
func fourDecimalPlaces(_ magnitude: Double) -> String {
  decimalPlaces(magnitude, places: 4)
}

/// decimalPlaces writes a magnitude, a finite number of zero or more, with `places` decimal
/// places, from 1 to 6, in Latin digits and a full stop, rounded half away from zero on its binary
/// value exactly, as `fourDecimalPlaces(_:)` writes four: the coordinates a readout copies are
/// written to five (`geo.readout.rows`).
func decimalPlaces(_ magnitude: Double, places: Int) -> String {
  let whole = magnitude.rounded(.down)
  // Subtracting the floor is exact for every finite double, so the fraction is the value's own.
  var units = roundedUnits(magnitude - whole, places: places)
  var carry: UInt64 = 0
  var scale: UInt64 = 1
  for _ in 0..<places {
    scale *= 10
  }
  if units == scale {
    carry = 1
    units = 0
  }
  let digits = String(units)
  return wholeDigits(whole, carry: carry) + "."
    + String(repeating: "0", count: places - digits.count) + digits
}

/// roundedUnits is a fraction, from zero to under one, as a whole number of units of the
/// `places`th decimal place, a half rounding up.
private func roundedUnits(_ fraction: Double, places: Int) -> UInt64 {
  if fraction == 0 { return 0 }
  let (significand, exponent) = binaryParts(fraction)
  // fraction × 10^places is significand × 5^places × 2^(exponent + places). The product of the
  // significand and the power of five is held in 128 bits, and for a fraction under one the power
  // of two is a division by 2^47 or more.
  var five: UInt64 = 1
  for _ in 0..<places {
    five *= 5
  }
  let (high, low) = significand.multipliedFullWidth(by: five)
  let shift = -(exponent + places)
  if shift > 128 { return 0 }
  func bit(_ index: Int) -> UInt64 {
    index >= 64 ? (high >> UInt64(index - 64)) & 1 : (low >> UInt64(index)) & 1
  }
  let quotient: UInt64 =
    switch shift {
    case 128: 0
    case 64...: high >> UInt64(shift - 64)
    default: (high &<< UInt64(64 - shift)) | (low >> UInt64(shift))
    }
  return bit(shift - 1) == 1 ? quotient + 1 : quotient
}

/// twoToThe63rd is the first whole double a 64-bit signed integer does not hold.
private let twoToThe63rd: Double = 9_223_372_036_854_775_808

/// wholeDigits writes a whole number of zero or more, plus a carry, in decimal digits.
private func wholeDigits(_ whole: Double, carry: UInt64) -> String {
  // A carry comes from a fraction, and only a double under 2^52 has one.
  if whole < twoToThe63rd { return String(UInt64(whole) + carry) }
  let limb: UInt64 = 1_000_000_000
  let (significand, exponent) = binaryParts(whole)
  // Little-endian limbs of nine digits, doubled up to thirty times a pass.
  var limbs = [significand % limb, significand / limb]
  var remaining = exponent
  while remaining > 0 {
    let step = min(remaining, 30)
    var up: UInt64 = 0
    for index in limbs.indices {
      let product = (limbs[index] << UInt64(step)) + up
      limbs[index] = product % limb
      up = product / limb
    }
    while up > 0 {
      limbs.append(up % limb)
      up /= limb
    }
    remaining -= step
  }
  while limbs.count > 1, limbs.last == 0 {
    limbs.removeLast()
  }
  var digits = String(limbs[limbs.count - 1])
  for limbValue in limbs.dropLast().reversed() {
    let text = String(limbValue)
    digits += String(repeating: "0", count: 9 - text.count) + text
  }
  return digits
}

/// binaryParts is a positive finite value as its whole significand and the power of two it is
/// scaled by: the implicit bit set for a normal value, and the exponent -1074 for a subnormal one.
private func binaryParts(_ value: Double) -> (significand: UInt64, exponent: Int) {
  let stored = value.significandBitPattern
  let biased = Int(value.exponentBitPattern)
  if biased == 0 { return (stored, -1_074) }
  return (stored | (1 << 52), biased - 1_075)
}
