/// profilePolyline is the line a profile's curve is drawn as (`geo.profile.chart-path`): its samples
/// joined in the order the series holds them, each where `profileX(_:totalDistance:window:)` and
/// `profileY(_:domain:)` draw it.
///
/// A window, its two ends in either order, draws the samples within it and the one just outside
/// each end, where there is one, at the x the window places them unclamped, so the line leaves the
/// frame at the ground's own slope rather than standing upright against its edges; a renderer clips
/// what runs past the frame. A window no sample reaches draws nothing, and so does a series with no
/// sample.
public func profilePolyline(
  _ series: ElevationSeries, domain: ElevationDomain, window: ProfileRange? = nil
) -> [PlotPoint] {
  let span = orderedWindow(window, totalDistance: series.totalDistance)
  return drawnSamples(series.points, window: window).map {
    PlotPoint(x: projectX($0.distance, span: span), y: profileY($0.elevation, domain: domain))
  }
}

/// drawnSamples is the samples a curve drawn over `window` draws: every one with no window, else
/// those the window holds and the one just outside each end, and none where no sample stands at or
/// past the window's start.
func drawnSamples(_ points: [ElevationPoint], window: ProfileRange?) -> ArraySlice<ElevationPoint> {
  guard let window else { return points[...] }
  let from = minimumNumber(window.from, window.to)
  let to = maximumNumber(window.from, window.to)
  guard var first = points.firstIndex(where: { $0.distance >= from }) else { return [] }
  var last = points.count - 1
  while last > first, points[last].distance > to {
    last -= 1
  }
  first = max(0, first - 1)
  last = min(points.count - 1, last + 1)
  return points[first...last]
}
