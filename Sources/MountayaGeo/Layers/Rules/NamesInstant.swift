import Foundation

/// instantLimitSeconds is how far from the epoch an instant every SDK holds may fall, in seconds:
/// 8.64e15 milliseconds, 100,000,000 days, the range of an ECMAScript or a Dart instant. A `Date`
/// holds instants past it, and no number at all, so the time's rules hold one to it themselves.
let instantLimitSeconds: Double = 8_640_000_000_000

/// namesInstant tells whether `instant` names an instant the time's rules hold
/// (`geo.layers.overlay-instant`): a number of seconds from the epoch, finite and within 8.64e15
/// milliseconds of it, the range every SDK holds a time to. A `Date` of no number, or past that
/// range, names none, as a pin that names no instant names none, and is read as none pinned.
package func namesInstant(_ instant: Date) -> Bool {
  let seconds = instant.timeIntervalSince1970
  return seconds.isFinite && abs(seconds) <= instantLimitSeconds
}
