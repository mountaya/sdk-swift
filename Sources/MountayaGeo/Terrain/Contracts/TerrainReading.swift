/// TerrainReading is the terrain read off the elevation tiles at a point
/// (`geo.terrain.elevation-sample`): its height, and how steep the ground is there and which way
/// it falls.
///
/// Two are equal where they hold the same numbers, `NaN` the same as `NaN` and 0 another than -0,
/// as every value of the geo layer compares, and no aspect is another value than any bearing.
/// Equal values hash alike.
public struct TerrainReading: Sendable, Hashable {
  /// elevation is the ground's height at the point, in meters.
  public var elevation: Double
  /// slope is the angle of the ground from the horizontal, in degrees: 0 on flat ground.
  public var slope: Double
  /// aspect is the compass bearing the ground falls towards, in degrees within [0, 360), or nil on
  /// flat ground, which faces nowhere.
  public var aspect: Double?

  /// Creates a reading of a height, a slope and the bearing it falls towards.
  public init(elevation: Double, slope: Double, aspect: Double?) {
    self.elevation = elevation
    self.slope = slope
    self.aspect = aspect
  }

  /// Two readings are equal where every number is the same and the aspects are both absent or the
  /// same number.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard sameNumber(lhs.elevation, rhs.elevation), sameNumber(lhs.slope, rhs.slope) else {
      return false
    }
    switch (lhs.aspect, rhs.aspect) {
    case (nil, nil): return true
    case (let left?, let right?): return sameNumber(left, right)
    default: return false
    }
  }

  /// hash feeds the height and the slope, then whether an aspect is stated and the aspect, as the
  /// same-number relation reads each.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: elevation)
    hasher.combine(sameNumber: slope)
    hasher.combine(aspect != nil)
    if let aspect {
      hasher.combine(sameNumber: aspect)
    }
  }
}
