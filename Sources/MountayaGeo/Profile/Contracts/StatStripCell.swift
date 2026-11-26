import MountayaClient

/// StatStripCell is one figure the stat strip states (`geo.profile.stat-strip`): which it is, and
/// its value in meters, seconds or degrees, or the difficulty as the itinerary writes it, before a
/// formatter writes any of it for a reader.
///
/// Two are equal where they are of one figure and hold the same value, a number by the same-number
/// relation and a difficulty by its scalars.
public enum StatStripCell: Sendable, Hashable {
  /// distance is a length, in meters.
  case distance(Double)
  /// duration is a time, in seconds.
  case duration(Double)
  /// ascent is the meters climbed.
  case ascent(Double)
  /// descent is the meters lost, stated positive.
  case descent(Double)
  /// elevation is an altitude, in meters above sea level.
  case elevation(Double)
  /// grade is a slope, in degrees.
  case grade(Double)
  /// difficulty is the hardest difficulty, as the itinerary writes it.
  case difficulty(RestSchema.TrailDifficultyType)

  /// stat is the figure the cell states.
  public var stat: StatStripStat {
    switch self {
    case .distance: .distance
    case .duration: .duration
    case .ascent: .ascent
    case .descent: .descent
    case .elevation: .elevation
    case .grade: .grade
    case .difficulty: .difficulty
    }
  }

  /// number is the cell's value where it is a number, nil for the difficulty.
  public var number: Double? {
    switch self {
    case .distance(let value), .duration(let value), .ascent(let value), .descent(let value),
      .elevation(let value), .grade(let value):
      value
    case .difficulty: nil
    }
  }

  /// Two cells are equal where they state one figure of the same value.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.stat == rhs.stat else { return false }
    if case .difficulty(let a) = lhs, case .difficulty(let b) = rhs { return sameText(a, b) }
    return sameNumber(lhs.number, rhs.number)
  }

  /// hash feeds the figure, then its value.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(stat)
    if case .difficulty(let difficulty) = self {
      hasher.combine(difficulty)
    } else {
      hasher.combine(sameNumber: number)
    }
  }
}
