import MountayaGeo

/// waypointRowTarget is what pointing a waypoint table's row writes to a map
/// (`map.profile.table-rows`): the marker at the sample of `series` nearest the place's pass, the
/// row being the place itself, and no stretch lit. Nothing where no row is pointed at.
func waypointRowTarget(_ row: ItineraryWaypointRow?, series: ElevationSeries) -> MapTarget {
  guard let row else { return MapTarget() }
  return MapTarget(
    lngLat: nearestSampleIndex(series.points, distance: row.to).map { series.points[$0].lngLat })
}
