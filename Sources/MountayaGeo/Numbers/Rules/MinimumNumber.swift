/// minimumNumber is the lesser of two numbers, `NaN` where either is `NaN`, and -0 where the two
/// are the two zeros, since -0 sorts below 0.
///
/// The standard library's `min` answers whichever argument a comparison with `NaN` leaves it
/// holding, so `min(.nan, 3)` and `min(3, .nan)` differ, and `Double.minimum` drops a quiet
/// `NaN`. Neither keeps an unknown value unknown, which every rule of the geo layer does.
func minimumNumber(_ a: Double, _ b: Double) -> Double {
  if a.isNaN || b.isNaN { return .nan }
  if a == b { return a.sign == .minus ? a : b }
  return a < b ? a : b
}
