/// anchoredDomain is the elevation range a chart is drawn against, by what its scale is anchored on
/// (`geo.profile.domain`): `route` frames the whole itinerary whatever the window, so a zoomed curve
/// keeps the height it had; `window` frames the stretch `window` holds, as `profileDomain(_:window:)`
/// reads one, so a zoomed section rescales to its own relief; and `seaLevel` moves only the floor of
/// the route's frame to zero, its ceiling kept, so a sea-level scale is the itinerary's own scale
/// extended downward rather than a second rounding.
public func anchoredDomain(
  _ series: ElevationSeries, anchor: ProfileAnchor, window: ProfileRange? = nil
) -> ElevationDomain {
  switch anchor {
  case .route: profileDomain(series)
  case .window: profileDomain(series, window: window)
  case .seaLevel: ElevationDomain(min: 0, max: profileDomain(series).max)
  }
}
