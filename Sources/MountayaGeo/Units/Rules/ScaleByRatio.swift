/// scaleByRatio answers a value times a numerator over a denominator, two whole magnitudes in one
/// quantity's base unit, the pair reduced by its greatest common divisor first. A factor that
/// reduces to a whole number multiplies once and one that reduces to a whole fraction divides
/// once, so a mile is 5,280 feet exactly rather than a product of two rounded factors. Any other
/// pair multiplies by its reduced numerator, then divides by its reduced denominator.
func scaleByRatio(_ value: Double, numerator: Int64, denominator: Int64) -> Double {
  let divisor = greatestCommonDivisor(numerator, denominator)
  let up = numerator / divisor
  let down = denominator / divisor
  if down == 1 { return value * Double(up) }
  if up == 1 { return value / Double(down) }
  return value * Double(up) / Double(down)
}

/// invertByRatio answers a numerator over a denominator, reduced as `scaleByRatio` reduces them,
/// divided by a value: a rate read as a pace, or a pace as a rate. A value of zero answers an
/// infinity, of the zero's sign.
func invertByRatio(_ value: Double, numerator: Int64, denominator: Int64) -> Double {
  let divisor = greatestCommonDivisor(numerator, denominator)
  let up = numerator / divisor
  let down = denominator / divisor
  if down == 1 { return Double(up) / value }
  return Double(up) / (value * Double(down))
}

/// greatestCommonDivisor is Euclid's, over two magnitudes above zero.
private func greatestCommonDivisor(_ larger: Int64, _ smaller: Int64) -> Int64 {
  var (larger, smaller) = (larger, smaller)
  while smaller != 0 {
    (larger, smaller) = (smaller, larger % smaller)
  }
  return larger
}
