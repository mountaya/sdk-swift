/// HeldAnalysis is what a map holds of a Data API result it drew, enough for an edit to merge a
/// patch onto and redraw: its kind, the input it was asked with, nil where the result was handed
/// over, the result, and the options it is drawn under (`map.analysis.edit`).
struct HeldAnalysis: Sendable {
  /// kind is the result's kind.
  let kind: AnalysisKind
  /// input is the input the result was asked with, or nil where it was handed over.
  var input: (any Sendable)?
  /// result is the result drawn.
  var result: any Sendable
  /// chosen is the suggested itinerary drawn solid, by its place in the result.
  var chosen: Int
  /// fit is how the camera frames the result once it is drawn, or nil for no fit.
  var fit: CameraFit?
}
