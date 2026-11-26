/// wrapLongitudePastRange keeps a longitude as it is written where it already lies within
/// [-180, 180], 180 included, and wraps any other as `wrapLongitude(_:)` does. A longitude a reader
/// or the wire wrote keeps its digits, -0 its sign; one a map counted past the antimeridian is
/// brought back by whole turns. A longitude that is not finite wraps to `NaN`.
public func wrapLongitudePastRange(_ longitude: Double) -> Double {
  abs(longitude) <= longitudeLimit ? longitude : wrapLongitude(longitude)
}
