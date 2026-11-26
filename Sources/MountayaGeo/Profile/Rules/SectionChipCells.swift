/// defaultSectionChipStats is what a section chip states where its caller names nothing, the
/// `defaultStats` `geo/profile-section-chips.json` declares: its leg's length and climb, the two a
/// reader compares two legs on.
public let defaultSectionChipStats: [SectionChipStat] = [.distance, .ascent]

/// sectionChipCells is what a section chip under a profile states about its leg, in the order
/// `stats` asks (`geo.profile.section-chips`): the leg's own length, climb and loss, a loss stated
/// positive as the wire states it, and its average grade (`sectionGrade(_:)`). A figure with no
/// value takes no cell, so a leg of an itinerary with no elevation states its length alone.
public func sectionChipCells(
  _ metrics: ItinerarySegmentRowMetrics, stats: [SectionChipStat] = defaultSectionChipStats
) -> [SectionChipCell] {
  stats.compactMap { stat in
    let value: Double? =
      switch stat {
      case .distance: metrics.sectionDistance
      case .ascent: metrics.sectionAscent
      case .descent: metrics.sectionDescent
      case .grade: sectionGrade(metrics)
      }
    return value.map { SectionChipCell(stat: stat, value: $0) }
  }
}
