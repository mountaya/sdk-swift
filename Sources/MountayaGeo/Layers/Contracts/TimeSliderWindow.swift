import Foundation

/// TimeSliderWindow is the forecast window a time slider spans, laid out around one clock reading
/// at one stop an hour (`geo.layers.time-window`): a stop is a whole number of hours from the
/// track's start, stop 0 the earliest instant the time-aware overlays hold, `nowValue` the stop of
/// the reading and `maxValue` the last.
///
/// A track has an instant at every stop or at none, `start` saying which: `timeSliderWindow(now:)`
/// lays out a track of no instant where the clock reads none, or where an end of the track would
/// fall more than 8.64e15 milliseconds from the epoch, the range every SDK holds a track to. Such a
/// track still runs from 0 to `maxValue`; every stop stands for no instant, and every instant is
/// placed at `nowValue`.
///
/// A track is held to the microsecond, so an instant half an hour from a stop is placed at the
/// later one exactly, whatever binary error a `Date` carries. Two are equal where they start at the
/// same instant, or both hold none.
public struct TimeSliderWindow: Sendable, Equatable {
  /// startMicroseconds is the instant stop 0 stands for, in microseconds from the epoch, or nil for
  /// a track of no instant.
  let startMicroseconds: Int64?

  /// Creates the track starting `startMicroseconds` from the epoch, or of no instant.
  init(startMicroseconds: Int64?) {
    self.startMicroseconds = startMicroseconds
  }

  /// start is the instant stop 0 stands for, or nil for a track of no instant.
  public var start: Date? {
    startMicroseconds.map { Date(timeIntervalSince1970: Double($0) / 1_000_000) }
  }

  /// nowValue is the stop that stands for the clock's reading, 71.
  public var nowValue: Int { timeWindowPastHours }

  /// maxValue is the track's last stop, its whole length in hours, 215.
  public var maxValue: Int { timeWindowPastHours + timeWindowFutureHours }

  /// date answers the instant the stop `value` stands for, the track's start plus its hours, or nil
  /// on a track of no instant and for a value that is no stop of the track.
  public func date(at value: Int) -> Date? {
    guard let start = startMicroseconds, (0...maxValue).contains(value) else { return nil }
    return Date(
      timeIntervalSince1970: Double(start + Int64(value) * microsecondsPerHour) / 1_000_000)
  }

  /// value answers the stop `instant` is placed at: its nearest, a half hour going to the later one,
  /// held to the track, so a pin the window has moved past still places a thumb at its nearest end.
  /// No pin, nil, is placed at `nowValue`, and so are an instant that names none and every instant
  /// on a track of no instant.
  public func value(at instant: Date?) -> Int {
    guard let start = startMicroseconds, let instant, namesInstant(instant) else {
      return nowValue
    }
    let at = Int64((instant.timeIntervalSince1970 * 1_000_000).rounded())
    let end = start + Int64(maxValue) * microsecondsPerHour
    // The ends first, so no distance past the track is counted in microseconds.
    if at <= start { return 0 }
    if at >= end { return maxValue }
    return Int((at - start + microsecondsPerHour / 2) / microsecondsPerHour)
  }
}

/// microsecondsPerHour is an hour, a stop of a time slider's track, in microseconds.
let microsecondsPerHour: Int64 = 3_600_000_000
