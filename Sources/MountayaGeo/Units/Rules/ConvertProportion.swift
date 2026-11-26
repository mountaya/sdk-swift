/// percentPerRatio is the percent in a ratio of one, the `percentPerRatio` the units fixtures
/// declare.
let percentPerRatio: Int64 = 100

/// convertProportion converts a value between a ratio and a percentage, a ratio of one being a
/// hundred percent. Nothing is clamped: a ratio of 2.5 is 250 percent.
public func convertProportion(_ value: Double, from: ProportionUnit, to: ProportionUnit)
  -> Double
{
  scaleByRatio(value, numerator: from.percent, denominator: to.percent)
}

extension ProportionUnit {
  /// percent is the unit's size in percent.
  fileprivate var percent: Int64 {
    switch self {
    case .percent: return 1
    case .ratio: return percentPerRatio
    }
  }
}
