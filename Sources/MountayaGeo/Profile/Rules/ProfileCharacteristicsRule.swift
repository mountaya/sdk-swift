import MountayaClient

/// profileCharacteristics folds the summary an itinerary's profile states from its segments'
/// stored metrics and its waypoints.
///
/// Distance, duration, ascent and descent are summed, the altitude band and the slope range,
/// `gradient_min` to `gradient_max`, are the extremes, and each stays nil until a segment states
/// it, a figure a segment leaves nil being left out. A duration some segments state and others do
/// not is marked partial; none stated is no duration, and not partial. The trail-difficulty range
/// is the easiest and the hardest stretch by `trailDifficultyRank(_:)`, a grade of no rank,
/// `unknown` included, taking no place on it, and of two grades of one rank the first listed holds.
/// The planned stops are the waypoints' `stop_duration` summed, nil where none states one. A sum
/// past the range of `Int` wraps rather than traps.
///
/// Its file is `ProfileCharacteristicsRule.swift`, since Swift refuses two files of one name in a
/// target and `ProfileCharacteristics.swift` is the answer type's.
public func profileCharacteristics(
  _ segments: [RestSchema.ItinerarySegment], waypoints: [RestSchema.ItineraryWaypoint] = []
) -> ProfileCharacteristics {
  var distance: Double?
  var duration: Double?
  var ascent: Int?
  var descent: Int?
  var altitudeMin: Int?
  var altitudeMax: Int?
  var slopeMin: Double?
  var slopeMax: Double?
  var withDuration = 0
  var easiest: (rank: Int, grade: RestSchema.TrailDifficultyType)?
  var hardest: (rank: Int, grade: RestSchema.TrailDifficultyType)?
  for segment in segments {
    distance = folded(distance, segment.distance, by: +)
    duration = folded(duration, segment.duration, by: +)
    if segment.duration != nil { withDuration += 1 }
    ascent = folded(ascent, segment.ascent, by: &+)
    descent = folded(descent, segment.descent, by: &+)
    altitudeMin = folded(altitudeMin, segment.altitude_min, by: min)
    altitudeMax = folded(altitudeMax, segment.altitude_max, by: max)
    slopeMin = folded(slopeMin, segment.gradient_min, by: minimumNumber)
    slopeMax = folded(slopeMax, segment.gradient_max, by: maximumNumber)
    for entry in segment.trail_difficulty_info ?? [] {
      guard let rank = trailDifficultyRank(entry.value) else { continue }
      if hardest.map({ rank > $0.rank }) ?? true { hardest = (rank, entry.value) }
      if easiest.map({ rank < $0.rank }) ?? true { easiest = (rank, entry.value) }
    }
  }
  var stopDuration: Int?
  for waypoint in waypoints {
    stopDuration = folded(stopDuration, waypoint.timing?.stop_duration ?? nil, by: &+)
  }
  return ProfileCharacteristics(
    distance: distance,
    duration: duration,
    durationPartial: withDuration > 0 && withDuration < segments.count,
    ascent: ascent,
    descent: descent,
    altitudeMin: altitudeMin,
    altitudeMax: altitudeMax,
    slopeMin: slopeMin,
    slopeMax: slopeMax,
    stopDuration: stopDuration,
    trailDifficultyMin: easiest?.grade,
    trailDifficultyMax: hardest?.grade
  )
}
