import MountayaClient

/// placeOnCurve places an itinerary's places on its profile, once for the pins, the names and the
/// drop lines (`geo.profile.curve-placement`).
///
/// Each pass of a place, as `resolveWaypoints(_:waypoints:)` places it on `geometry`, that stands
/// within `window`, its two ends included, stands at the x `profileX(_:totalDistance:window:)`
/// draws its distance at. It is a pin on the curve, at the curve's altitude at its distance read on
/// the line between the two samples either side, unless the place is not pinned or the series has
/// no sample; a name under the axis where the place divides the itinerary (`dividesRoute`), the
/// curve's height under it, nil with no sample; and a cut-off where the place publishes one,
/// elevation or not. A pass outside the window is left out rather than clipped, since a pin and a
/// name are read aloud.
public func placeOnCurve(
  _ series: ElevationSeries,
  geometry: GeoJSONGeometry?,
  domain: ElevationDomain,
  window: ProfileRange,
  places: [ProfilePlace]
) -> CurvePlacement {
  var placement = CurvePlacement(pins: [], dividers: [], cutoffs: [])
  for pass in waypointPasses(geometry, waypoints: places.map(\.placement)) {
    let distance = pass.distance
    guard distance >= window.from, distance <= window.to else { continue }
    let place = places[pass.listed]
    let x = profileX(distance, totalDistance: series.totalDistance, window: window)
    let altitude = elevationAt(series.points, distance: distance)
    if place.isPinned, let altitude {
      placement.pins.append(
        CurvePin(
          key: pass.key, place: place, distance: distance, x: x,
          y: profileY(altitude, domain: domain), altitude: altitude))
    }
    if place.dividesRoute {
      placement.dividers.append(
        CurveDivider(
          key: pass.key, place: place, distance: distance, x: x,
          y: altitude.map { profileY($0, domain: domain) }))
    }
    if let cutoffAt = place.details?.timing?.cutoffAt {
      placement.cutoffs.append(
        CurveCutoff(key: pass.key, place: place, distance: distance, x: x, cutoffAt: cutoffAt))
    }
  }
  return placement
}
