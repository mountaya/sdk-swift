/// clampNumber holds a number within a range: the lower bound where it lies under it, the upper
/// where it lies over it, and itself otherwise, so a number that is `NaN` stays `NaN`.
///
/// `min(max(value, lower), upper)` would read a `NaN` as one of the bounds, a known number for an
/// unknown one.
func clampNumber(_ value: Double, to range: ClosedRange<Double>) -> Double {
  if value < range.lowerBound { return range.lowerBound }
  if value > range.upperBound { return range.upperBound }
  return value
}
