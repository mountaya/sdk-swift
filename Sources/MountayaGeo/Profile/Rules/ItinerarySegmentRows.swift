/// itinerarySegmentRows is an itinerary's legs as its table rows, in chain order
/// (`geo.profile.segment-rows`), the rows a segment table lists and a profile's section chips state.
///
/// Each row spans the length of its leg's own lines on the distance axis
/// (`profileLength`), from where the row before it ended, held to the series' length, and a leg
/// with no geometry spans nothing. Its figures are the ones stated for it, `stated[leg.id]` field
/// by field over the leg's own, the server's, over those read off the one cumulative scan of the
/// whole series between its two ends (`rangeTotals(_:from:to:)`), so the last row's running climb
/// is the itinerary's; a leg spanning nothing derives none, since a figure of zero is one a reader
/// believes. The altitude band is the stated one over the derived; the duration and the difficulty
/// are the stated ones, which no geometry implies.
///
/// The running `distance`, `ascent` and `descent` add each row's section figure to the row
/// before's, nil until a figure adds to one, so an itinerary with no elevation states no climb; a
/// stated running figure replaces the running total and carries into the rows after it, so the
/// rows after an official figure follow it rather than drifting back.
public func itinerarySegmentRows(
  _ series: ElevationSeries,
  legs: [ItineraryLeg],
  stated: [String: ItinerarySegmentRowMetrics] = [:]
) -> [ItinerarySegmentRow] {
  var rows: [ItinerarySegmentRow] = []
  var from: Double = 0
  var travelled: Double = 0
  var climbed: Double?
  var dropped: Double?
  for leg in legs {
    let length = profileLength(leg.geometry)
    let to = minimumNumber(series.totalDistance, from + length)
    let derived = length > 0 ? rangeTotals(series, from: from, to: to) : nil
    let own = stated[leg.id]

    let sectionDistance =
      own?.sectionDistance ?? leg.sectionDistance ?? derived.map { _ in to - from }
    let sectionAscent = own?.sectionAscent ?? leg.sectionAscent.map(Double.init) ?? derived?.ascent
    let sectionDescent =
      own?.sectionDescent ?? leg.sectionDescent.map(Double.init) ?? derived?.descent

    travelled += sectionDistance ?? 0
    climbed = sectionAscent.map { (climbed ?? 0) + $0 } ?? climbed
    dropped = sectionDescent.map { (dropped ?? 0) + $0 } ?? dropped

    let metrics = ItinerarySegmentRowMetrics(
      distance: own?.distance ?? travelled,
      sectionDistance: sectionDistance,
      ascent: own?.ascent ?? climbed,
      descent: own?.descent ?? dropped,
      sectionAscent: sectionAscent,
      sectionDescent: sectionDescent,
      altitudeMin: own?.altitudeMin ?? leg.altitudeMin.map(Double.init) ?? derived?.elevationMin,
      altitudeMax: own?.altitudeMax ?? leg.altitudeMax.map(Double.init) ?? derived?.elevationMax,
      duration: own?.duration ?? leg.duration,
      difficulty: own?.difficulty
    )
    travelled = metrics.distance ?? travelled
    climbed = metrics.ascent ?? climbed
    dropped = metrics.descent ?? dropped

    rows.append(
      ItinerarySegmentRow(
        key: leg.id, id: leg.id, memberIds: leg.memberIds, name: leg.name, color: leg.color,
        index: rows.count, from: from, to: to, metrics: metrics))
    from = to
  }
  return rows
}
