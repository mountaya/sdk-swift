/// rowStandsFor tells whether a segment table's row answers to the segment `id`
/// (`geo.profile.row-match`): its own, or, where the row is a collapsed group, one of the segments
/// it stands for, since a map names the segment its tiles carry, which for a group is always a
/// member. No id is no row's.
public func rowStandsFor(_ row: ItinerarySegmentRow, id: String?) -> Bool {
  guard let id else { return false }
  return sameText(row.id, id) || row.memberIds.contains { sameText($0, id) }
}
