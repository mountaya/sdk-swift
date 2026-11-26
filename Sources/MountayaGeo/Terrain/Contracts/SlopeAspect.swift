/// SlopeAspect is how steep the ground is at a point, and which way it falls.
///
/// Two are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another than -0,
/// as every value of the geo layer compares, and no aspect is another value than any bearing.
/// Equal values hash alike.
public struct SlopeAspect: Sendable, Hashable {
  /// slope is the angle of the ground from the horizontal, in degrees: 0 on flat ground.
  public var slope: Double
  /// aspect is the compass bearing the ground falls towards, in degrees within [0, 360), 0 north
  /// and 90 east, or nil on flat ground, which faces nowhere. A bearing of 0 is a north-facing
  /// slope.
  public var aspect: Double?

  /// Creates a slope and the bearing it falls towards, nil for flat ground.
  public init(slope: Double, aspect: Double?) {
    self.slope = slope
    self.aspect = aspect
  }

  /// Two answers are equal where the slopes are the same number and the aspects are both absent
  /// or the same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard sameNumber(lhs.slope, rhs.slope) else { return false }
    switch (lhs.aspect, rhs.aspect) {
    case (nil, nil): return true
    case (let left?, let right?): return sameNumber(left, right)
    default: return false
    }
  }

  /// hash feeds the slope, then whether an aspect is stated and the aspect, as the same-number
  /// relation reads each.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: slope)
    hasher.combine(aspect != nil)
    if let aspect {
      hasher.combine(sameNumber: aspect)
    }
  }
}
