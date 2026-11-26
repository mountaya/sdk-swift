/// maximumNumber is the greater of two numbers, `NaN` where either is `NaN`, and 0 where the two
/// are the two zeros, since 0 sorts above -0.
///
/// The standard library's `max` answers whichever argument a comparison with `NaN` leaves it
/// holding, so `max(.nan, 3)` and `max(3, .nan)` differ, and `Double.maximum` drops a quiet
/// `NaN`. Neither keeps an unknown value unknown, which every rule of the geo layer does.
func maximumNumber(_ a: Double, _ b: Double) -> Double {
  if a.isNaN || b.isNaN { return .nan }
  if a == b { return a.sign == .minus ? b : a }
  return a > b ? a : b
}
