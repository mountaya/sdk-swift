/// convertLength converts a value from one length unit to another through the exact values that
/// define them: an inch is 2.54 cm, a foot twelve inches and a mile 5,280 feet. Nothing is
/// clamped, and a value that is not finite converts to itself.
public func convertLength(_ value: Double, from: LengthUnit, to: LengthUnit) -> Double {
  scaleByRatio(value, numerator: from.tenthsOfMillimeter, denominator: to.tenthsOfMillimeter)
}

extension LengthUnit {
  /// tenthsOfMillimeter is the unit's length in tenths of a millimeter, the largest unit in which
  /// every defining value is whole.
  var tenthsOfMillimeter: Int64 {
    let inch: Int64 = 254
    let meter: Int64 = 10_000
    switch self {
    case .centimeter: return 100
    case .foot: return 12 * inch
    case .inch: return inch
    case .kilometer: return 1_000 * meter
    case .meter: return meter
    case .mile: return 5_280 * 12 * inch
    }
  }
}
