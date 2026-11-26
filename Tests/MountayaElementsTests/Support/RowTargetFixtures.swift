import MountayaGeo

/// series is five samples 250 meters apart up a meridian, the profile fixtures' own.
let rowTargetSeries = ElevationSeries(
  points: (0..<5).map { index in
    ElevationPoint(
      distance: Double(index) * 250, elevation: 1000, lngLat: [6, 45 + Double(index) * 0.00225],
      index: index)
  },
  totalDistance: 1000, minElevation: 1000, maxElevation: 1000)

/// segmentRow is a segment table's row of `id` over `from` to `to`, standing for `members`.
func segmentRow(_ id: String, from: Double, to: Double, members: [String] = [])
  -> ItinerarySegmentRow
{
  ItinerarySegmentRow(
    key: id, id: id, memberIds: members, name: id, index: 0, from: from, to: to,
    metrics: ItinerarySegmentRowMetrics())
}
