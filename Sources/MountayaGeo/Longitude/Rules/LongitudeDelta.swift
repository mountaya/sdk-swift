/// longitudeDelta is the signed short way from one longitude to another, in degrees, positive
/// eastward: the plain difference where it is at most half a turn, half a turn included either
/// way, and the difference wrapped by whole turns otherwise. From 179.9 to -179.9 is 0.2, and from
/// 0 to 180 is 180. A longitude that is not finite answers `NaN`.
public func longitudeDelta(from: Double, to: Double) -> Double {
  wrapLongitudePastRange(to - from)
}
