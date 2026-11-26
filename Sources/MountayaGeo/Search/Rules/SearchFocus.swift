/// The latitude of a pole, which a focus holds its latitude within.
private let poleLatitude = 90.0

/// searchFocus is the point a search round is ranked around, as the wire writes one
/// (`geo.search.focus`): a camera's `center`, `[longitude, latitude]`, its longitude brought within
/// [-180, 180] by whole turns, one already within it kept as written, 180 and -0 included
/// (`wrapLongitudePastRange(_:)`), and its latitude held within the poles.
///
/// A map that pans across the antimeridian keeps counting, so its centre reads 197.5 for the place
/// the wire writes as -162.5, and the Data API refuses a focus outside the range whatever box is
/// sent beside it.
///
/// `nil` for a centre that names no point, one with fewer than two numbers or a coordinate that is
/// no finite number, which a round reads as a camera with nothing to read: it ranks around nothing
/// and confines nothing either.
func searchFocus(_ center: [Double]) -> [Double]? {
  guard center.count >= 2, center[0].isFinite, center[1].isFinite else { return nil }
  return [
    wrapLongitudePastRange(center[0]), clampNumber(center[1], to: -poleLatitude...poleLatitude),
  ]
}
