/// defaultSegmentTableColumns is the columns a segment table draws where its caller names none, the
/// `defaultColumns` `geo/profile-segment-table-cells.json` declares: the leg's name, its shape, how
/// far and how much, which is what a roadbook is read for.
public let defaultSegmentTableColumns: [SegmentTableColumn] = [
  .segment, .profile, .distance, .elevation,
]

/// segmentRowCell is what `column` of a segment table states about `row`'s leg
/// (`geo.profile.segment-table-cells`): its name; the whole itinerary's sparkline with its own
/// stretch lit in its colour; its distance over the running distance; its climb and loss over the
/// running climb alone; its altitude band, or the one end known where the other is not, the floor
/// first; its duration; and its difficulty as the itinerary writes it, never translated, since the
/// taxonomy is the itinerary's. Its file is `SegmentRowCellRule.swift`, since
/// `SegmentRowCell.swift` is the answer type's.
public func segmentRowCell(_ row: ItinerarySegmentRow, column: SegmentTableColumn)
  -> SegmentRowCell
{
  let metrics = row.metrics
  switch column {
  case .segment:
    return .segment(name: row.name)
  case .profile:
    return .profile(lit: ProfileRange(from: row.from, to: row.to), color: row.color)
  case .distance:
    return .distance(leg: metrics.sectionDistance, total: metrics.distance)
  case .elevation:
    return .elevation(
      ascent: metrics.sectionAscent, descent: metrics.sectionDescent, totalAscent: metrics.ascent)
  case .altitude:
    let lowest = metrics.altitudeMin.flatMap { $0.isFinite ? $0 : nil }
    let highest = metrics.altitudeMax.flatMap { $0.isFinite ? $0 : nil }
    if let lowest, let highest {
      return .altitude(band: AltitudeRange(min: lowest, max: highest), single: nil)
    }
    return .altitude(band: nil, single: lowest ?? highest)
  case .duration:
    return .duration(seconds: metrics.duration)
  case .difficulty:
    return .difficulty(text: metrics.difficulty)
  }
}
