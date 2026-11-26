import MountayaClient

/// ProfileCharacteristics is the summary an itinerary's profile states, folded from its segments'
/// stored metrics and its waypoints. Each figure is nil until a segment states it, and each keeps
/// the wire's own type.
///
/// Two are equal where they hold the same figures, numbers compared as every value of the geo layer
/// compares.
public struct ProfileCharacteristics: Sendable, Hashable {
  /// distance is the segments' distances summed, in meters.
  public var distance: Double?
  /// duration is the segments' durations summed, in seconds: moving time, the stops apart.
  public var duration: Double?
  /// durationPartial is whether some segments state a duration and others do not, so `duration` is
  /// not the whole route's.
  public var durationPartial: Bool
  /// ascent is the segments' ascents summed, in meters.
  public var ascent: Int?
  /// descent is the segments' descents summed, in meters.
  public var descent: Int?
  /// altitudeMin is the lowest altitude any segment states, in meters.
  public var altitudeMin: Int?
  /// altitudeMax is the highest altitude any segment states, in meters.
  public var altitudeMax: Int?
  /// slopeMin is the steepest descending gradient any segment states, in degrees.
  public var slopeMin: Double?
  /// slopeMax is the steepest ascending gradient any segment states, in degrees.
  public var slopeMax: Double?
  /// stopDuration is the waypoints' planned stops summed, in seconds, apart from `duration` since
  /// it is no moving time.
  public var stopDuration: Int?
  /// trailDifficultyMin is the easiest stretch's trail difficulty, by its rank within its scale.
  public var trailDifficultyMin: RestSchema.TrailDifficultyType?
  /// trailDifficultyMax is the hardest stretch's trail difficulty, by its rank within its scale.
  public var trailDifficultyMax: RestSchema.TrailDifficultyType?

  /// Creates a summary from its figures.
  public init(
    distance: Double?,
    duration: Double?,
    durationPartial: Bool,
    ascent: Int?,
    descent: Int?,
    altitudeMin: Int?,
    altitudeMax: Int?,
    slopeMin: Double?,
    slopeMax: Double?,
    stopDuration: Int?,
    trailDifficultyMin: RestSchema.TrailDifficultyType?,
    trailDifficultyMax: RestSchema.TrailDifficultyType?
  ) {
    self.distance = distance
    self.duration = duration
    self.durationPartial = durationPartial
    self.ascent = ascent
    self.descent = descent
    self.altitudeMin = altitudeMin
    self.altitudeMax = altitudeMax
    self.slopeMin = slopeMin
    self.slopeMax = slopeMax
    self.stopDuration = stopDuration
    self.trailDifficultyMin = trailDifficultyMin
    self.trailDifficultyMax = trailDifficultyMax
  }

  /// Two summaries are equal where every figure is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.distance, rhs.distance) && sameNumber(lhs.duration, rhs.duration)
      && lhs.durationPartial == rhs.durationPartial && lhs.ascent == rhs.ascent
      && lhs.descent == rhs.descent && lhs.altitudeMin == rhs.altitudeMin
      && lhs.altitudeMax == rhs.altitudeMax && sameNumber(lhs.slopeMin, rhs.slopeMin)
      && sameNumber(lhs.slopeMax, rhs.slopeMax) && lhs.stopDuration == rhs.stopDuration
      && lhs.trailDifficultyMin == rhs.trailDifficultyMin
      && lhs.trailDifficultyMax == rhs.trailDifficultyMax
  }

  /// hash feeds every figure, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: duration)
    hasher.combine(durationPartial)
    hasher.combine(ascent)
    hasher.combine(descent)
    hasher.combine(altitudeMin)
    hasher.combine(altitudeMax)
    hasher.combine(sameNumber: slopeMin)
    hasher.combine(sameNumber: slopeMax)
    hasher.combine(stopDuration)
    hasher.combine(trailDifficultyMin)
    hasher.combine(trailDifficultyMax)
  }
}
