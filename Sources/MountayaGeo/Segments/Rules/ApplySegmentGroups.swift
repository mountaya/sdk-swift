import MountayaClient

/// segmentGroupIdPrefix opens the id of the one segment a collapsed group stands as, `group:` then
/// the group's id. A segment's own id is a UUID, which never holds a colon, so no stored segment
/// can carry it.
public let segmentGroupIdPrefix = "group:"

/// applySegmentGroups projects an itinerary's chain of segments, in chain order, for display with
/// each of its groups collapsed into one segment, so a group reads as one leg.
///
/// A group's members become one segment at the place of its first member in the chain, the others
/// dropped from where they stand. Its id is `segmentGroupIdPrefix` then the group's id, and it
/// carries the group's id, name, colour, speed, revision, creator and creation instant, and the
/// first member's mode, position and start, with no description and no steps. Its geometry is a
/// GeometryCollection of every line its members hold, in chain order, a directions member's vias
/// left out. Each analysis range, slope, speed, surface, way type and trail difficulty, is its
/// member's own, its indexes moved on by the count of positions the lines of the members before it
/// hold, so every band stands where it stood; the five lists are empty where no member states an
/// entry. Its road access ranges are moved on the same way, each keeping its member's values as
/// they are, a member that states none, nil, adding none, and are nil where no member states them:
/// one member that states `[]`, analysed with no restriction found, makes the group's `[]`, so a
/// group with an analysed member never reads as unanalysed. Distance, duration, ascent and descent
/// are summed and the altitude and gradient extremes taken across the members, a figure a member
/// leaves nil left out, and nil where none states it.
///
/// A segment of no group, or of a group `groups` does not list, passes as itself, and with no group
/// to collapse the answer is `segments` as they are.
public func applySegmentGroups(
  _ segments: [RestSchema.ItinerarySegment], groups: [RestSchema.ItinerarySegmentGroup]
) -> [RestSchema.ItinerarySegment] {
  if groups.isEmpty { return segments }
  // Of two groups listed under one id, the later is the one a segment reads.
  var byId: [String: RestSchema.ItinerarySegmentGroup] = [:]
  for group in groups {
    byId[group.id] = group
  }
  var members: [String: [RestSchema.ItinerarySegment]] = [:]
  for segment in segments {
    guard let groupId = segment.group_id, byId[groupId] != nil else { continue }
    members[groupId, default: []].append(segment)
  }
  if members.isEmpty { return segments }
  var collapsed: Set<String> = []
  var projected: [RestSchema.ItinerarySegment] = []
  projected.reserveCapacity(segments.count)
  for segment in segments {
    guard let groupId = segment.group_id, let group = byId[groupId] else {
      projected.append(segment)
      continue
    }
    guard collapsed.insert(groupId).inserted else { continue }
    projected.append(collapsedGroup(group, members: members[groupId] ?? [segment], head: segment))
  }
  return projected
}

/// The one segment a group stands as over its members, in chain order, `head` the first.
private func collapsedGroup(
  _ group: RestSchema.ItinerarySegmentGroup,
  members: [RestSchema.ItinerarySegment],
  head: RestSchema.ItinerarySegment
) -> RestSchema.ItinerarySegment {
  var lines: [GeoJSONGeometry] = []
  var slope: [RestSchema.SlopeInfo] = []
  var speed: [RestSchema.SpeedInfo] = []
  var surface: [RestSchema.SurfaceInfo] = []
  var wayType: [RestSchema.WayTypeInfo] = []
  var trailDifficulty: [RestSchema.TrailDifficultyInfo] = []
  // Nil until a member states its road access, so the group tells unanalysed from analysed.
  var roadAccess: [RestSchema.RoadAccessInfo]?
  var figures = Figures()
  // The count of positions the members before this one hold, which its indexes are moved on by.
  var offset = 0
  for member in members {
    var positions = 0
    for line in linesOf(member.geojson) {
      lines.append(.lineString(GeoJSONLineString(coordinates: line)))
      positions += line.count
    }
    slope += (member.slope_info ?? []).map {
      RestSchema.SlopeInfo(
        from_index: $0.from_index &+ offset, to_index: $0.to_index &+ offset, value: $0.value)
    }
    speed += (member.speed_info ?? []).map {
      RestSchema.SpeedInfo(
        from_index: $0.from_index &+ offset, to_index: $0.to_index &+ offset, value: $0.value)
    }
    surface += (member.surface_info ?? []).map {
      RestSchema.SurfaceInfo(
        from_index: $0.from_index &+ offset, to_index: $0.to_index &+ offset, value: $0.value)
    }
    wayType += (member.way_type_info ?? []).map {
      RestSchema.WayTypeInfo(
        from_index: $0.from_index &+ offset, to_index: $0.to_index &+ offset, value: $0.value)
    }
    trailDifficulty += (member.trail_difficulty_info ?? []).map {
      RestSchema.TrailDifficultyInfo(
        from_index: $0.from_index &+ offset, to_index: $0.to_index &+ offset, value: $0.value)
    }
    if let stated = member.road_access_info {
      roadAccess =
        (roadAccess ?? [])
        + stated.map {
          RestSchema.RoadAccessInfo(
            from_index: $0.from_index &+ offset, to_index: $0.to_index &+ offset,
            values: $0.values)
        }
    }
    offset &+= positions
    figures.fold(member)
  }
  return RestSchema.ItinerarySegment(
    altitude_max: figures.altitudeMax,
    altitude_min: figures.altitudeMin,
    ascent: figures.ascent,
    color: group.color,
    created_at: group.created_at,
    created_by: group.created_by,
    descent: figures.descent,
    description: nil,
    distance: figures.distance,
    duration: figures.duration,
    geojson: .geometryCollection(GeoJSONGeometryCollection(geometries: lines)),
    gradient_max: figures.gradientMax,
    gradient_min: figures.gradientMin,
    group_id: group.id,
    id: segmentGroupIdPrefix + group.id,
    itinerary_id: group.itinerary_id,
    mode: head.mode,
    name: group.name,
    position: head.position,
    revision: group.revision,
    road_access_info: roadAccess,
    slope_info: slope,
    speed: group.speed,
    speed_info: speed,
    start_at: head.start_at,
    steps: [],
    surface_info: surface,
    trail_difficulty_info: trailDifficulty,
    way_type_info: wayType
  )
}

/// The figures a group folds from its members, each nil until one states it.
private struct Figures {
  var altitudeMax: Int?
  var altitudeMin: Int?
  var ascent: Int?
  var descent: Int?
  var distance: Double?
  var duration: Double?
  var gradientMax: Double?
  var gradientMin: Double?

  /// Folds a member's figures in, a sum past the range of `Int` wrapping rather than trapping.
  mutating func fold(_ member: RestSchema.ItinerarySegment) {
    altitudeMax = folded(altitudeMax, member.altitude_max, by: max)
    altitudeMin = folded(altitudeMin, member.altitude_min, by: min)
    ascent = folded(ascent, member.ascent, by: &+)
    descent = folded(descent, member.descent, by: &+)
    distance = folded(distance, member.distance, by: +)
    duration = folded(duration, member.duration, by: +)
    gradientMax = folded(gradientMax, member.gradient_max, by: maximumNumber)
    gradientMin = folded(gradientMin, member.gradient_min, by: minimumNumber)
  }
}
