import Foundation

/// timeWindowPastHours is how far before the clock's reading a time slider's track reaches, in
/// hours (`geo.layers.time-window`): an hour short of the three days the Tile API draws a stamped
/// overlay back to, so a request asked at the first stop is still inside that window when it
/// arrives.
let timeWindowPastHours = 71

/// timeWindowFutureHours is how far after the clock's reading a time slider's track reaches, in
/// hours: the six days the Tile API draws a stamped overlay ahead.
let timeWindowFutureHours = 144

/// timeSliderWindow lays a time slider's track out around `now`, the clock's reading
/// (`geo.layers.time-window`): from 71 hours before it to 144 hours after it, one stop an hour,
/// stop 71 standing for the reading itself.
///
/// A clock that reads no instant, or one whose track would reach more than 8.64e15 milliseconds
/// from the epoch, the range an ECMAScript or a Dart instant holds, to which every SDK holds a
/// track, lays out the same track with no instant (`TimeSliderWindow.start` nil): its stops stand
/// for none, and every instant is placed at the stop of the reading. It reads no clock: a panel
/// hands it its clock's reading each time it draws, so the window follows the clock with no timer
/// of its own.
///
/// ```swift
/// let track = timeSliderWindow(now: clock.now)
/// let thumb = track.value(at: layers.state.instant)
/// ```
public func timeSliderWindow(now: Date) -> TimeSliderWindow {
  // A track the range holds runs either side of a reading the range holds, `namesInstant(_:)`,
  // which is counted in microseconds within 64 bits.
  guard namesInstant(now) else { return TimeSliderWindow(startMicroseconds: nil) }
  let seconds = now.timeIntervalSince1970
  let limit = Int64(instantLimitSeconds) * 1_000_000
  let start =
    Int64((seconds * 1_000_000).rounded()) - Int64(timeWindowPastHours) * microsecondsPerHour
  let end = start + Int64(timeWindowPastHours + timeWindowFutureHours) * microsecondsPerHour
  return TimeSliderWindow(startMicroseconds: start >= -limit && end <= limit ? start : nil)
}
