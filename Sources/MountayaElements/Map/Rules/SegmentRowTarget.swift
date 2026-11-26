import MountayaClient
import MountayaGeo

/// segmentRowTarget is what pointing a segment table's row writes to a map
/// (`map.profile.table-rows`): the marker at the sample of `series` nearest the leg's end, the
/// earlier of two as near, the place a roadbook's row is about arriving at, and the leg lit as its
/// stretch of the series (`lineBetween(_:from:to:)`), so a row standing for several legs lights
/// them all. Nothing where no row is pointed at.
func segmentRowTarget(_ row: ItinerarySegmentRow?, series: ElevationSeries) -> MapTarget {
  guard let row else { return MapTarget() }
  return MapTarget(
    lngLat: nearestSampleIndex(series.points, distance: row.to).map { series.points[$0].lngLat },
    stretch: lineBetween(series.points, from: row.from, to: row.to))
}
