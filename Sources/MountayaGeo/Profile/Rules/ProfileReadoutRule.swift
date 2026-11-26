/// defaultReadoutStats is what a cursor readout states where its caller names nothing, the
/// `defaultStats` `geo/profile-cursor-readout.json` declares: where the cursor stands, then what it
/// took to get there.
public let defaultReadoutStats: [ReadoutStat] = [.distance, .elevation, .ascent, .descent]

/// profileReadout is what a profile states about `point`, the sample its cursor stands on, in the
/// order `stats` asks (`geo.profile.cursor-readout`): the sample's own distance and altitude, never
/// a point read between two samples; the ascent and the descent from the itinerary's start, read
/// off the one cumulative scan of the whole series (`rangeTotals(_:from:to:)`), so the figure and
/// the last row of a table beside it are one number; the grade across the window centred on it
/// (`gradeAt(_:distance:)`); and the stretch of `stretches` its distance reads
/// (`stretchAt(_:distance:)`), the later of two at a meter they share. A figure with no value is
/// left out. Its file is `ProfileReadoutRule.swift`, since `ProfileReadout.swift` is the answer
/// type's.
public func profileReadout(
  _ series: ElevationSeries,
  at point: ElevationPoint,
  stats: [ReadoutStat] = defaultReadoutStats,
  stretches: [ProfileClass] = []
) -> ProfileReadout {
  let climbs = stats.contains(.ascent) || stats.contains(.descent)
  let reached = climbs ? rangeTotals(series, from: 0, to: point.distance) : nil
  let cells = stats.compactMap { stat -> ReadoutCell? in
    let value: Double? =
      switch stat {
      case .distance: point.distance
      case .elevation: point.elevation
      case .ascent: reached?.ascent
      case .descent: reached?.descent
      }
    return value.map { ReadoutCell(stat: stat, value: $0) }
  }
  return ProfileReadout(
    cells: cells, grade: gradeAt(series.points, distance: point.distance),
    stretch: stretchAt(stretches, distance: point.distance))
}
