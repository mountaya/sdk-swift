import MountayaClient

/// committedPace is an itinerary's committed effective pace over its segments, in km/h: their total
/// stored `distance`, in meters, over their total stored `duration`, in seconds. It is the pace
/// that reproduces the duration the segments state, weighted by duration, never the mean of each
/// segment's own pace.
///
/// A segment is left out unless its distance is a finite number of zero or more and its duration a
/// finite number above zero: one with no timing is not counted as instant, and a negative or
/// non-finite figure never reaches the total. Nil where no segment is left, none at all included.
public func committedPace(_ segments: [RestSchema.ItinerarySegment]) -> Double? {
  var meters: Double = 0
  var seconds: Double = 0
  for segment in segments {
    guard let distance = segment.distance, let duration = segment.duration,
      distance.isFinite, distance >= 0, duration.isFinite, duration > 0
    else { continue }
    meters += distance
    seconds += duration
  }
  guard seconds > 0 else { return nil }
  return convertSpeed(meters / seconds, from: .meterPerSecond, to: .kilometerPerHour)
}
