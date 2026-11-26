/// profileDomain is the elevation range a series is drawn against (`geo.profile.domain`),
/// anchored on the itinerary's own extent rather than on sea level, since the shape of a climb is
/// what a profile is read for: a ridge between 2,400 m and 2,600 m is a ridge, not a flat line four
/// fifths of the way up an empty chart.
///
/// With no window it frames the series' stated extent, `minElevation` to `maxElevation`. A window,
/// its two ends in either order, frames the stretch it holds: the lowest and the highest the curve
/// stands between the window's ends, read at each end on the line between the two samples either
/// side of it and at every sample between them. A window that holds the whole curve is no zoom and
/// frames the stated extent, since the samples are thinned and the extent is not; and so does a
/// window the samples do not reach, so the frame keeps its scale with no curve in it. The extent is
/// then widened and rounded by `extentDomain(min:max:)`.
public func profileDomain(_ series: ElevationSeries, window: ProfileRange? = nil) -> ElevationDomain
{
  let extent = windowedExtent(series, window: window)
  return extentDomain(min: extent.lowest, max: extent.highest)
}

/// The elevation range of a series over a window, the stated extent where the window frames the
/// whole series or none of it.
private func windowedExtent(_ series: ElevationSeries, window: ProfileRange?) -> (
  lowest: Double?, highest: Double?
) {
  let whole = (lowest: series.minElevation, highest: series.maxElevation)
  guard let window, let first = series.points.first, let last = series.points.last else {
    return whole
  }
  let from = minimumNumber(window.from, window.to)
  let to = maximumNumber(window.from, window.to)
  if from <= first.distance && to >= last.distance { return whole }
  guard let band = altitudeBand(series.points, from: from, to: to) else { return whole }
  return (band.lowest, band.highest)
}
