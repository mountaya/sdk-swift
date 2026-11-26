import Foundation
import MountayaClient

/// defaultDistanceTickCount is how many stops a distance axis is labelled at where its caller asks
/// for no other count, the `defaultTarget` `geo/distance-ticks.json` declares.
public let defaultDistanceTickCount = 6

/// The three decades between a kilometer and a meter.
private let metersDecades = 3

/// distanceTicks is the stops a distance axis over the range `from` to `to`, in meters, is labelled
/// at, on the 1, 2, 5 lattice of the reader's distance unit: kilometers for a metric `length`,
/// miles for an imperial one. A range given backwards is read in order.
///
/// The step is the range's span in that unit over `target`, the stop count asked for, brought to
/// one, two or five times a power of ten: the smallest of those at least the rough step, a
/// normalized step above 5 becoming ten, the next decade up. Every multiple of the step within the
/// range is a stop, with its value in the display unit, its position in meters and the fraction
/// digits its label needs, the negated exponent of the step and never under zero. A metric stop's
/// meters are the same lattice three decades up, so a kilometer stop lands on a whole count of
/// meters.
///
/// A range of no width, or a `target` under one, has no stops; so has a range that is no finite
/// number, or one too narrow for a double to hold its step, and the stops end where a double can
/// count no further multiple. A system other than imperial reads as metric.
public func distanceTicks(
  from: Double, to: Double, length: RestSchema.UnitLength,
  target: Int = defaultDistanceTickCount
) -> [DistanceTick] {
  let imperial = isImperial(length)
  let unitMeters = convertLength(1, from: imperial ? .mile : .kilometer, to: .meter)
  let low = minimumNumber(from, to) / unitMeters
  let high = maximumNumber(from, to) / unitMeters
  let span = high - low
  guard span > 0, span.isFinite, target >= 1 else { return [] }

  let rough = span / Double(target)
  var exponent = Int(floor(log10(rough)))
  // Held to the decade the rough step is in, whatever the platform's logarithm rounds to.
  while scaled(1, exponent: exponent) > rough { exponent -= 1 }
  while scaled(1, exponent: exponent + 1) <= rough { exponent += 1 }
  let normalized = exponent >= 0 ? rough / powerOfTen(exponent) : rough * powerOfTen(-exponent)
  var mantissa: Double =
    if normalized > 5 { 10 } else if normalized > 2 { 5 } else if normalized > 1 { 2 } else { 1 }
  // Ten is one, a decade up, so the fraction digits read off the exponent alone.
  if mantissa == 10 {
    mantissa = 1
    exponent += 1
  }
  let step = scaled(mantissa, exponent: exponent)
  guard step > 0 else { return [] }
  let fractionDigits = max(0, -exponent)

  var ticks: [DistanceTick] = []
  var count = ceil(low / step)
  while true {
    let value = scaled(count * mantissa, exponent: exponent)
    guard value <= high else { break }
    let meters =
      imperial ? value * unitMeters : scaled(count * mantissa, exponent: exponent + metersDecades)
    ticks.append(DistanceTick(value: value, meters: meters, fractionDigits: fractionDigits))
    // Past 2^53 a double counts no further multiple, and the next stop would be this one again.
    let next = count + 1
    guard next != count else { break }
    count = next
  }
  return ticks
}

/// `mantissa` times ten to `exponent`, divided by the exact power where the exponent is negative.
private func scaled(_ mantissa: Double, exponent: Int) -> Double {
  exponent >= 0 ? mantissa * powerOfTen(exponent) : mantissa / powerOfTen(-exponent)
}
