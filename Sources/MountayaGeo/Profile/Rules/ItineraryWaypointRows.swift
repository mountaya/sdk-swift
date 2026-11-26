import MountayaClient

/// itineraryWaypointRows is an itinerary's places as its waypoint rows, one per pass of a place in
/// itinerary order (`geo.profile.waypoint-rows`), each placed on `geometry` as
/// `resolveWaypoints(_:waypoints:)` places it, so a loop passing a place twice lists it twice and a
/// loop's start and finish stand at zero and at the total with no radius to tune.
///
/// Each row is reached from the row before, the first from the itinerary's start: its `from` is
/// where the row before stands and its `to` where its place stands. Its altitude is the curve's at
/// its distance, read on the line between the two samples either side; its section figures and its
/// running climb and loss are read off the one cumulative scan of the whole series
/// (`rangeTotals(_:from:to:)`), so the last row's running climb is the itinerary's.
///
/// A place that divides the itinerary states its `metrics` over the derived figures, field by field,
/// on its primary pass alone, the one the order its places are listed in gives it, so an official
/// running figure resets the totals once. From the first row that states one, each running total is
/// the row before's plus this row's section, a stated running figure replacing it; the rows before
/// read the scan digit for digit. Every placed pass is a row, dividing or not.
public func itineraryWaypointRows(
  _ series: ElevationSeries, geometry: GeoJSONGeometry?, places: [ProfilePlace]
) -> [ItineraryWaypointRow] {
  var previous: Double = 0
  var running = (ascent: Double?.none, descent: Double?.none, distance: 0.0)
  var follows = false
  return waypointPasses(geometry, waypoints: places.map(\.placement)).enumerated().map {
    index, pass in
    let place = places[pass.listed]
    let to = pass.distance
    let from = previous
    previous = to
    let reaching = rangeTotals(series, from: from, to: to)
    let fromStart = rangeTotals(series, from: 0, to: to)
    let stated = pass.isPrimary && place.dividesRoute ? place.metrics : nil
    follows = follows || statesRowFigure(stated)

    let sectionDistance = stated?.sectionDistance ?? reaching.distance
    let sectionAscent = stated?.sectionAscent ?? reaching.ascent
    let sectionDescent = stated?.sectionDescent ?? reaching.descent
    if follows {
      running = (
        ascent: stated?.ascent ?? carried(running.ascent, adding: sectionAscent),
        descent: stated?.descent ?? carried(running.descent, adding: sectionDescent),
        distance: stated?.distance ?? running.distance + sectionDistance
      )
    } else {
      running = (ascent: fromStart.ascent, descent: fromStart.descent, distance: to)
    }
    return ItineraryWaypointRow(
      key: pass.key, place: place, index: index, from: from, to: to,
      metrics: ItineraryWaypointRowMetrics(
        distance: running.distance, sectionDistance: sectionDistance, ascent: running.ascent,
        descent: running.descent, sectionAscent: sectionAscent, sectionDescent: sectionDescent,
        altitude: elevationAt(series.points, distance: to)))
  }
}

/// Whether stated figures hold one a waypoint row has a cell for: a section's distance, climb or
/// loss, or a running one.
private func statesRowFigure(_ stated: ItinerarySegmentRowMetrics?) -> Bool {
  guard let stated else { return false }
  return [
    stated.ascent, stated.descent, stated.distance, stated.sectionAscent, stated.sectionDescent,
    stated.sectionDistance,
  ].contains { $0 != nil }
}

/// A running total with a section's figure added, an absent figure leaving it as it is.
private func carried(_ total: Double?, adding section: Double?) -> Double? {
  guard let section else { return total }
  return (total ?? 0) + section
}
