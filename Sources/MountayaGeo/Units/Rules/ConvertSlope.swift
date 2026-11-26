import Foundation

/// convertSlope converts a value between degrees, a percentage grade and a rise-over-run ratio
/// through the tangent: a grade is the ratio in hundredths and an angle its arctangent, so
/// forty-five degrees is a hundred percent, not forty-five. A descent keeps its sign, a value in
/// its own unit is returned as it is, never taken through the tangent and back, and nothing is
/// clamped: 90 degrees or more is the tangent as it falls.
public func convertSlope(_ value: Double, from: SlopeUnit, to: SlopeUnit) -> Double {
  if from == to { return value }
  let ratio: Double
  switch from {
  case .degrees: ratio = tan(value * radiansPerDegree)
  case .percentage: ratio = value / Double(percentPerRatio)
  case .ratio: ratio = value
  }
  switch to {
  case .degrees: return atan(ratio) * degreesPerRadian
  case .percentage: return ratio * Double(percentPerRatio)
  case .ratio: return ratio
  }
}
