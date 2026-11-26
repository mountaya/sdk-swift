/// CurvePlacement is an itinerary's places as its profile draws them, each pass within the window
/// once (`geo.profile.curve-placement`): the pins on the curve, the names under the distance axis
/// and the cut-off marks, each in itinerary order, read once so the pins, the names and the drop
/// lines agree.
public struct CurvePlacement: Sendable, Hashable {
  /// pins is the passes pinned on the curve.
  public var pins: [CurvePin]
  /// dividers is the passes that divide the itinerary, named under its axis.
  public var dividers: [CurveDivider]
  /// cutoffs is the passes that publish a cut-off.
  public var cutoffs: [CurveCutoff]

  /// Creates a placement from its pins, its dividers and its cut-offs.
  public init(pins: [CurvePin], dividers: [CurveDivider], cutoffs: [CurveCutoff]) {
    self.pins = pins
    self.dividers = dividers
    self.cutoffs = cutoffs
  }
}
