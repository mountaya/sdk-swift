import Foundation

/// maxFractionDigits is the most fraction digits a number is rounded to; a request for more reads
/// this many.
let maxFractionDigits = 20

/// The magnitude, scaled to the digits kept, from which the rounding leaves a value as it is:
/// 2^48. Under it a double's neighbours are so close that only one decimal of one more digit than
/// kept reads as it, so the halfway decimal is that one or none.
private let scaledLimit: Double = 281_474_976_710_656

/// The powers of ten a double holds exactly, 10^0 to 10^22.
private let exactPowersOfTen: [Double] = {
  var powers: [Double] = []
  var power: Double = 1
  for _ in 0...22 {
    powers.append(power)
    power *= 10
  }
  return powers
}()

/// powerOfTen is 10 to the power `exponent`, read from 0 up: exact to 10^22, which is every power a
/// double holds exactly, and a product of exact powers past it.
func powerOfTen(_ exponent: Int) -> Double {
  let largest = exactPowersOfTen.count - 1
  var remaining = max(0, exponent)
  var power: Double = 1
  while remaining > largest {
    power *= exactPowersOfTen[largest]
    remaining -= largest
  }
  return power * exactPowersOfTen[remaining]
}

/// roundHalfAwayFromZero is a value rounded to `fractionDigits` places, half away from zero on its
/// decimal value: the decimal a reader would write the double as, never the binary value it holds.
/// 0.85 is held as 0.849999..., and to one place it is 0.9, as it reads; 2.675 to two places is
/// 2.68.
///
/// Each number a reader is shown is rounded here, before any formatter sees it, so the figure is
/// the same in every SDK: Foundation rounds half to even by default, and on the binary value, and
/// `Double.rounded()` rounds the binary value too, so 0.85 times ten would round to 8. The answer is
/// the double nearest the rounded decimal, which a formatter writes with no further rounding.
///
/// A value that rounds to zero is +0, so it is printed with no sign: -0.3 to a whole degree is 0,
/// never -0, which reads as a descent that is not there. A value that is not finite comes back as
/// it is, and so does one so large that no place it is rounded to is a fraction of it.
/// `fractionDigits` is read within 0 and `maxFractionDigits`.
func roundHalfAwayFromZero(_ value: Double, fractionDigits: Int) -> Double {
  guard value.isFinite else { return value }
  let scale = powerOfTen(min(max(fractionDigits, 0), maxFractionDigits))
  let magnitude = abs(value)
  let scaled = magnitude * scale
  if scaled >= scaledLimit { return value }
  let lower = floor(scaled)
  // The halfway decimal above `lower`, as the double nearest it: an odd count of halves over a
  // power of ten, each exact, divided once. A value that is that double reads as the halfway
  // decimal and is rounded away from zero; any other lies wholly on one side of it.
  let halfway = (2 * lower + 1) / (2 * scale)
  let count = magnitude >= halfway ? lower + 1 : lower
  if count == 0 { return 0 }
  let rounded = count / scale
  return value < 0 ? -rounded : rounded
}
