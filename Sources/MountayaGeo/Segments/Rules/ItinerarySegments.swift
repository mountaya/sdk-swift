import MountayaClient

/// itinerarySegments is an itinerary's legs: its segments in chain order, by their `position`, two
/// at one position in the order they are listed, each group `groups` lists collapsed into one leg
/// as `applySegmentGroups(_:groups:)` collapses it, under the id `segmentGroupIdPrefix` then the
/// group's id, naming the segments it stands for in chain order (`geo.data.itinerary-segments`). A
/// segment of no group, or of a group `groups` does not list, is a leg of its own and lists no
/// member.
///
/// Each leg carries its name, its colour where it states one and its geometry, and states the
/// server's figures as its own section: the distance, the ascent, the descent, the duration and
/// the altitude band its segment stores, or that a group sums and spans across its members, a
/// figure the server does not state being nil.
public func itinerarySegments(
  _ segments: [RestSchema.ItinerarySegment], groups: [RestSchema.ItinerarySegmentGroup]
) -> [ItineraryLeg] {
  let chain = inChainOrder(segments, position: \.position)
  // Every member of a listed group is collapsed, so a leg whose group is listed is a collapsed one
  // whatever its id. The groups are keyed as `applySegmentGroups(_:groups:)` keys them, so the
  // members named are the ones it collapsed.
  let listed = Set(groups.map(\.id))
  var members: [String: [String]] = [:]
  for segment in chain {
    guard let groupId = segment.group_id, listed.contains(groupId) else { continue }
    members[groupId, default: []].append(segment.id)
  }
  return applySegmentGroups(chain, groups: groups).map { leg in
    ItineraryLeg(
      id: leg.id,
      memberIds: leg.group_id.flatMap { listed.contains($0) ? members[$0] : nil } ?? [],
      name: leg.name,
      color: leg.color,
      geometry: leg.geojson,
      sectionDistance: leg.distance,
      sectionAscent: leg.ascent,
      sectionDescent: leg.descent,
      duration: leg.duration,
      altitudeMin: leg.altitude_min,
      altitudeMax: leg.altitude_max
    )
  }
}
