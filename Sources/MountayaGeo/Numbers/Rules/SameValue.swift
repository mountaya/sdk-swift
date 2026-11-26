/// sameValue tells whether two values a caller hands the geo layer are the same: two numbers by the
/// same-number relation, `NaN` the same as `NaN` and 0 another than -0, two lists of numbers number
/// by number, and any other two by their own `==`.
///
/// It is how a generic value, such as an analysis band's or a token's, compares as every value of
/// the geo layer does: a band of slope `NaN` beside another of `NaN` is one value, which IEEE
/// equality would answer the other way round.
func sameValue<Value: Equatable>(_ a: Value, _ b: Value) -> Bool {
  if let a = a as? Double, let b = b as? Double {
    return sameNumber(a, b)
  }
  if let a = a as? [Double], let b = b as? [Double] {
    return sameNumbers(a, b)
  }
  return a == b
}

/// sameValue tells whether two values a value may leave absent are the same: both absent, or both
/// present and the same, as `sameValue(_:_:)` reads two values.
func sameValue<Value: Equatable>(_ a: Value?, _ b: Value?) -> Bool {
  switch (a, b) {
  case (nil, nil): return true
  case (let a?, let b?): return sameValue(a, b)
  default: return false
  }
}

extension Hasher {
  /// Feeds a value as `sameValue(_:_:)` reads it: a number or a list of numbers as the same-number
  /// relation reads it, any other value as it hashes itself.
  mutating func combine<Value: Hashable>(sameValue value: Value) {
    if let number = value as? Double {
      combine(sameNumber: number)
    } else if let numbers = value as? [Double] {
      combine(sameNumbers: numbers)
    } else {
      combine(value)
    }
  }

  /// Feeds a value a value may leave absent: whether it is present, then the value as
  /// `sameValue(_:_:)` reads it.
  mutating func combine<Value: Hashable>(sameValue value: Value?) {
    combine(value != nil)
    if let value {
      combine(sameValue: value)
    }
  }
}
