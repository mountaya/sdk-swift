/// profileAreaPath is the area filled under a profile's curve (`geo.profile.chart-path`): a move to
/// the first drawn sample's x at the bottom of the square, a line along each sample of
/// `profilePolyline(_:domain:window:)`, a line down to the bottom of the square at the last drawn
/// sample's x, and a close. It is closed against the bottom of the square rather than the baseline,
/// so the fill reads as ground under the itinerary, and is empty where the curve draws nothing.
public func profileAreaPath(
  _ series: ElevationSeries, domain: ElevationDomain, window: ProfileRange? = nil
) -> [PlotCommand] {
  let line = profilePolyline(series, domain: domain, window: window)
  guard let first = line.first, let last = line.last else { return [] }
  return [.move(PlotPoint(x: first.x, y: profileViewBox))] + line.map { .line($0) } + [
    .line(PlotPoint(x: last.x, y: profileViewBox)), .close,
  ]
}
