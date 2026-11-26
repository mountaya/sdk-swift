/// sectionGrade is a leg's average grade, in degrees (`geo.profile.section-chips`): its climb less
/// its loss, over its length. The average rather than the steepest meter, since a chip a few
/// characters wide is read as how hard a leg is; the itinerary's steepest is the stat strip's. Nil
/// where a figure is missing or the leg has no length.
public func sectionGrade(_ metrics: ItinerarySegmentRowMetrics) -> Double? {
  guard let distance = metrics.sectionDistance, distance > 0, let ascent = metrics.sectionAscent,
    let descent = metrics.sectionDescent
  else { return nil }
  return convertSlope((ascent - descent) / distance, from: .ratio, to: .degrees)
}
