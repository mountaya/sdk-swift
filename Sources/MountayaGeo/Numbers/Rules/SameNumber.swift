/// sameNumber tells whether two numbers are the same number, the relation every value of the geo
/// layer is compared by: `NaN` is the same as `NaN`, and 0 is another number than -0, as
/// `geo.camera.route-content` states for a route.
///
/// It compares the bit patterns, every `NaN` read as one. IEEE equality, which `==` on two
/// `Double` values is, says `NaN` equals no number and that the two zeros are one, so a value
/// compared by it would differ from itself and hash apart from a value it equals. It is the
/// package's, so a value of the map compares as Geo's values do, and no consumer's: every value
/// that holds a number is `Hashable` by it.
package func sameNumber(_ a: Double, _ b: Double) -> Bool {
  sameNumberBits(a) == sameNumberBits(b)
}

/// sameNumbers tells whether two lists hold the same numbers in the same order, each compared
/// by `sameNumber(_:_:)`. A synthesized `==` on `[Double]` compares by IEEE equality instead, so a
/// position or a box compares by this.
package func sameNumbers(_ a: [Double], _ b: [Double]) -> Bool {
  a.count == b.count && zip(a, b).allSatisfy { sameNumber($0, $1) }
}

/// sameNumber tells whether two figures a value may leave absent are the same: both absent, or both
/// present and the same number, as `sameNumber(_:_:)` reads two numbers.
func sameNumber(_ a: Double?, _ b: Double?) -> Bool {
  switch (a, b) {
  case (nil, nil): return true
  case (let a?, let b?): return sameNumber(a, b)
  default: return false
  }
}

/// sameNumberBits is the bit pattern the same-number relation compares: the number's own, and
/// one pattern for every `NaN`, whatever payload it carries.
func sameNumberBits(_ value: Double) -> UInt64 {
  value.isNaN ? Double.nan.bitPattern : value.bitPattern
}

extension Hasher {
  /// Feeds a number as the same-number relation reads it, so two values it calls equal hash
  /// alike.
  mutating func combine(sameNumber value: Double) {
    combine(sameNumberBits(value))
  }

  /// Feeds a figure a value may leave absent: whether it is present, then the number as the
  /// same-number relation reads it.
  mutating func combine(sameNumber value: Double?) {
    combine(value != nil)
    if let value {
      combine(sameNumber: value)
    }
  }

  /// Feeds a list of numbers, its length then each number as the same-number relation reads it.
  mutating func combine(sameNumbers values: [Double]) {
    combine(values.count)
    for value in values {
      combine(sameNumber: value)
    }
  }
}
