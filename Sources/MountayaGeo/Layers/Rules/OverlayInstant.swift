import Foundation

/// overlayInstant is the moment a map's time-dependent surfaces show (`geo.layers.overlay-instant`):
/// the tiles a server stamps with an instant, and any surface that states the moment it shows.
///
/// A pinned instant is itself, whatever the clock reads: behind the pin, ahead of it, and under a
/// clock that reads none. With none pinned it is the start of the minute `now`, the clock's reading,
/// falls in, the reading floored to a whole minute from the epoch, so a reading before the epoch
/// falls in the minute before it. Every surface that reads it therefore shows one moment, and moves
/// when the minute does. A pin that names no instant, a `Date` of no number or one past the 8.64e15
/// milliseconds every SDK holds a time to (`namesInstant(_:)`), is read as none pinned.
///
/// It keeps no time and reads no clock: the caller hands over the clock's reading, and asks again
/// when the pin changes or the minute turns. Nil, with none pinned, under a clock that reads no
/// instant: there is no moment to show, and a surface draws nothing for it.
///
/// ```swift
/// let shown = overlayInstant(pinned: layers.state.instant, now: clock.now)
/// ```
public func overlayInstant(pinned: Date?, now: Date) -> Date? {
  if let pinned, namesInstant(pinned) {
    return pinned
  }
  let seconds = now.timeIntervalSince1970
  guard seconds.isFinite else { return nil }
  // Floored rather than truncated, so a reading before the epoch falls in the minute before it.
  let minute = Date(timeIntervalSince1970: (seconds / 60).rounded(.down) * 60)
  return namesInstant(minute) ? minute : nil
}
