/// convertSpeed converts a value from one speed unit to another. A rate is its length over its
/// time and a pace its time over its length, each through the exact values of its parts, so a
/// conversion between two of one form scales by the ratio of the parts and one across the forms
/// takes the reciprocal: 4.5 km/h is 13.333 minutes per kilometer.
///
/// A rate of zero is a pace of infinity and a pace of zero a rate of infinity, as the division
/// answers, and an infinite rate a pace of zero; nothing is clamped or refused.
public func convertSpeed(_ value: Double, from: SpeedUnit, to: SpeedUnit) -> Double {
  let sourceLength = from.length.tenthsOfMillimeter
  let sourceTime = from.time.milliseconds
  let targetLength = to.length.tenthsOfMillimeter
  let targetTime = to.time.milliseconds
  switch (from.isPace, to.isPace) {
  case (true, true):
    return scaleByRatio(
      value, numerator: sourceTime * targetLength, denominator: sourceLength * targetTime)
  case (false, false):
    return scaleByRatio(
      value, numerator: sourceLength * targetTime, denominator: sourceTime * targetLength)
  case (true, false):
    return invertByRatio(
      value, numerator: sourceLength * targetTime, denominator: sourceTime * targetLength)
  case (false, true):
    return invertByRatio(
      value, numerator: sourceTime * targetLength, denominator: sourceLength * targetTime)
  }
}

extension SpeedUnit {
  /// isPace is true for a unit that is a pace, a time per distance, rather than a rate.
  var isPace: Bool {
    self == .minutePerKilometer || self == .minutePerMile
  }

  /// length is the length the unit is stated over.
  fileprivate var length: LengthUnit {
    switch self {
    case .kilometerPerHour, .minutePerKilometer: return .kilometer
    case .meterPerSecond: return .meter
    case .milePerHour, .minutePerMile: return .mile
    }
  }

  /// time is the time the unit is stated over.
  fileprivate var time: DurationUnit {
    switch self {
    case .kilometerPerHour, .milePerHour: return .hour
    case .meterPerSecond: return .second
    case .minutePerKilometer, .minutePerMile: return .minute
    }
  }
}
