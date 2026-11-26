/// defaultStatStripStats is what the stat strip states where its caller names nothing, the
/// `defaultStats` `geo/profile-stat-strip.json` declares: the itinerary's length, its climb, its
/// loss and its highest point. The steepest grade, read beside three totals, would read as an
/// average, and no geometry implies a duration or a difficulty.
public let defaultStatStripStats: [StatStripStat] = [.distance, .ascent, .descent, .elevation]

/// statStripCells is what the stat strip over a profile states, in the order `stats` asks
/// (`geo.profile.stat-strip`): the itinerary's length, its duration, its climb and its loss, its
/// highest altitude, its steepest grade and its hardest difficulty, as `characteristics` states
/// them. While a scrub stands, `cursor`, the distance, the altitude and the grade are the cursor's
/// own, never the itinerary's in their place, so a cursor where no grade reads states no grade. A
/// figure with no value takes no cell, so an itinerary with no elevation states no climb rather
/// than a climb of zero.
public func statStripCells(
  _ characteristics: ResolvedCharacteristics,
  cursor: StatStripCursor?,
  stats: [StatStripStat] = defaultStatStripStats
) -> [StatStripCell] {
  stats.compactMap { stat in
    switch stat {
    case .distance:
      (cursor.map(\.distance) ?? characteristics.distance).map(StatStripCell.distance)
    case .duration:
      characteristics.duration.map(StatStripCell.duration)
    case .ascent:
      characteristics.ascent.map(StatStripCell.ascent)
    case .descent:
      characteristics.descent.map(StatStripCell.descent)
    case .elevation:
      (cursor.map(\.elevation) ?? characteristics.altitudeMax).map(StatStripCell.elevation)
    case .grade:
      (cursor == nil ? characteristics.slopeMax : cursor?.grade).map(StatStripCell.grade)
    case .difficulty:
      characteristics.trailDifficultyMax.map(StatStripCell.difficulty)
    }
  }
}
