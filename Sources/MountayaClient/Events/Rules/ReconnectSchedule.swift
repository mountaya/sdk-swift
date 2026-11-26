/// ReconnectSchedule decides when a reader opens a stream again after an open without progress,
/// and when it gives the stream up.
///
/// The wait is a uniform draw from zero to a ceiling that doubles per consecutive open without
/// progress, the full jitter `sdk/SPEC.md` section 2 has every retry take, for the reason given
/// there. Where that open was a 429 or a 503 naming its wait in `Retry-After`, the reopen waits
/// that instead, a wait of 0 seconds included, with section 2's draw of up to a second above it,
/// since an open sooner meets the same answer. An open that made progress, or that ended on a
/// `reconnect`, resets the count and is followed at once.
enum ReconnectSchedule {
  /// Count is what a reader counts of its opens since the last that made progress, or since the
  /// last `reconnect`.
  struct Count: Sendable, Hashable {
    /// opens is every open without progress, which the ceiling of the next wait doubles with.
    var opens = 0
    /// unavailableOpens is those of them answered 503 on a stream whose rules hold such opens to
    /// time, which are not among the reopens it stops after.
    var unavailableOpens = 0
    /// firstUnavailable is when the first of those was answered, on the client's clock, or nil
    /// before one.
    var firstUnavailable: Duration?
  }

  /// next counts one more open without progress, which failed with `failure`, or closed where it
  /// is nil, and ended at `now` on the client's clock, and returns the count after it with the
  /// wait before the next open, or with nil where the reader stops instead.
  ///
  /// An open answered 503, on a stream whose rules hold such opens to time, stops the reader where
  /// it comes `maxUnavailable` or more after the first of them; it is not counted among the
  /// reopens, and an open that failed otherwise in between neither restarts that time nor counts
  /// toward it. Every other open stops the reader where the opens without progress, but those
  /// answered 503, outnumber the stream's reopens. Either way the ceiling doubles with every open.
  ///
  /// `draw` is a uniform draw from zero to one, taken before every wait.
  static func next(
    after failure: MountayaError?,
    count: Count,
    at now: Duration,
    rules: EventStreamRules,
    draw: Double
  ) -> (count: Count, wait: Duration?) {
    var count = count
    count.opens += 1
    if let maxUnavailable = rules.maxUnavailable, status(of: failure) == 503 {
      let first = count.firstUnavailable ?? now
      count.firstUnavailable = first
      count.unavailableOpens += 1
      if now - first >= maxUnavailable {
        return (count, nil)
      }
    } else if let maxReopens = rules.maxReopens, count.opens - count.unavailableOpens > maxReopens {
      return (count, nil)
    }
    if let named = namedWait(failure) {
      return (count, named + .milliseconds(draw * milliseconds(Backoff.retryAfterJitter)))
    }
    return (count, drawnWait(afterOpensWithoutProgress: count.opens, rules: rules, draw: draw))
  }

  /// drawnWait returns the schedule's wait after `withoutProgress` opens in a row made none: a
  /// uniform draw from zero to the ceiling, which starts at the stream's base, doubles per open and
  /// stops growing at its most.
  static func drawnWait(
    afterOpensWithoutProgress withoutProgress: Int, rules: EventStreamRules, draw: Double
  ) -> Duration {
    let growth = Double(sign: .plus, exponent: max(withoutProgress, 1) - 1, significand: 1)
    let ceiling = min(milliseconds(rules.maxWait), milliseconds(rules.baseWait) * growth)
    return .milliseconds(draw * ceiling)
  }

  /// namedWait returns the wait a failed open's answer names: the whole seconds a 429's or a
  /// 503's `Retry-After` states, 0 included, and nil for any other failure and for one that names
  /// none.
  static func namedWait(_ failure: MountayaError?) -> Duration? {
    guard case .api(let error)? = failure, error.status == 429 || error.status == 503 else {
      return nil
    }
    return error.retryAfter
  }

  private static func status(of failure: MountayaError?) -> Int? {
    guard case .api(let error)? = failure else { return nil }
    return error.status
  }

  private static func milliseconds(_ duration: Duration) -> Double {
    let (seconds, attoseconds) = duration.components
    return Double(seconds) * 1000 + Double(attoseconds) / 1e15
  }
}
