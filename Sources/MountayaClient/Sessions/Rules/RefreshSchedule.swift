import Foundation

/// RefreshSchedule decides when a session token is minted again: before it expires, never
/// after a 401, since the request that discovers an expiry is the one the user is waiting on.
enum RefreshSchedule {
  /// Plan is when the next mint happens, counted from the moment the token arrived.
  struct Plan: Sendable, Hashable {
    /// delay is how long after the token arrived the next mint happens.
    let delay: Duration
    /// isArmed is false where the delay is under `minTimer`. That token arrived already spent,
    /// or the clock is far enough out of step to look that way, and the next plan is the one
    /// for a run of spent tokens.
    let isArmed: Bool
  }

  /// refreshMargin is the most headroom a token is re-minted with, and the wait for a token
  /// whose expiry is unknown.
  static let refreshMargin: Duration = .seconds(60)
  /// minTimer is the shortest delay that is armed, and the first wait after a spent token.
  static let minTimer: Duration = .seconds(5)
  /// maxTimer is the longest a wait goes without re-reading the wall clock.
  static let maxTimer: Duration = .seconds(600)

  /// plan returns when a token with `lifetime` left is re-minted, or, where its expiry did not
  /// parse and `lifetime` is nil, the flat margin.
  ///
  /// The margin is proportional and capped: the lifetime less the smaller of `refreshMargin`
  /// and half the lifetime, so a short-lived token still gets headroom instead of a zero
  /// delay. An unknown expiry is not a spent token: the token is usable and only its deadline
  /// is unknown.
  static func plan(lifetime: Duration?) -> Plan {
    guard let lifetime else {
      return Plan(delay: refreshMargin, isArmed: true)
    }
    let delay = lifetime - min(refreshMargin, lifetime / 2)
    return Plan(delay: delay, isArmed: delay >= minTimer)
  }

  /// plan returns when the next mint happens after `consecutiveSpent` tokens in a row arrived
  /// already spent: `minTimer`, doubled for each one after the first, up to `refreshMargin`.
  ///
  /// The doubling is what keeps a skewed clock from turning into a call to the application's
  /// mint endpoint every few seconds for as long as the skew lasts. A failed mint is planned
  /// the same way.
  static func plan(consecutiveSpent: Int) -> Plan {
    var delay = minTimer
    var doublings = max(consecutiveSpent, 1) - 1
    while doublings > 0, delay < refreshMargin {
      delay *= 2
      doublings -= 1
    }
    return Plan(delay: min(delay, refreshMargin), isArmed: true)
  }

  /// hop returns the next wait toward `deadline` from `now`, or nil once the deadline has
  /// passed and the mint is due.
  ///
  /// The wait is held as an instant and walked down in hops of at most `maxTimer`, each
  /// re-reading the wall clock, so a device that slept through its timer mints on waking
  /// rather than on the schedule it slept through. A hop is not a mint.
  static func hop(toward deadline: Date, now: Date) -> Duration? {
    let remaining = deadline.timeIntervalSince(now)
    guard remaining > 0 else { return nil }
    return min(.seconds(remaining), maxTimer)
  }
}
