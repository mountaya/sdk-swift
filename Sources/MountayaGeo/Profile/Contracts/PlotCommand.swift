/// PlotCommand is one command of a path drawn in a profile's plot, in the order a renderer draws
/// them: the area under a profile's curve is a move, the lines along the curve and down to the
/// bottom of the plot, and a close (`geo.profile.chart-path`).
public enum PlotCommand: Sendable, Hashable {
  /// move starts the path at a point.
  case move(PlotPoint)
  /// line draws a straight line to a point.
  case line(PlotPoint)
  /// close draws the path back to where it started.
  case close
}
