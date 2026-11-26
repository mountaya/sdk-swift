/// Backoff decides how long the client waits before repeating an attempt, and whether that
/// wait fits the call's budget at all.
///
/// The wait is a uniform draw from zero to a capped exponential, full jitter rather than the
/// exponential itself: a fixed schedule synchronises every client that failed in the same
/// moment into retrying in the same moment. A `Retry-After` replaces the schedule with the
/// seconds it names plus a draw of up to one second, so the clients one second refused do not
/// all come back in the same millisecond.
enum Backoff {
  /// retryAfterJitter is the most a `Retry-After` wait is lengthened by its draw.
  static let retryAfterJitter: Duration = .seconds(1)

  /// keyInUseMinimum is the least a repeat of a 409 whose key is still in use waits, whatever
  /// its answer names, so that every repeat spends the budget that bounds it.
  static let keyInUseMinimum: Duration = .seconds(1)

  /// delay returns the wait after the attempt numbered `attempt`, counting the first as zero,
  /// or nil where that wait does not fit what the waits the call took before it, `waited`, left
  /// of the policy's budget: such a wait is not taken, and the attempt settles with the error its
  /// answer maps to.
  ///
  /// `draw` is a uniform draw from zero to one, taken from a `RandomSource` before every wait.
  /// A `Retry-After` value replaces the schedule outright, ceiling included. A wait that ends
  /// exactly at the budget fits it. A wait shorter than `minimum` is lengthened to it before it
  /// is held to the budget.
  static func delay(
    after attempt: Int,
    policy: RetryPolicy,
    draw: Double,
    retryAfter: Duration?,
    waited: Duration,
    minimum: Duration = .zero
  ) -> Duration? {
    let wait: Duration
    if let retryAfter {
      wait = retryAfter + .milliseconds(draw * milliseconds(retryAfterJitter))
    } else {
      // 2^attempt as a floating-point power of two, which is exact and never overflows: past
      // the largest finite value it is infinity, and the ceiling caps it.
      let growth = Double(sign: .plus, exponent: attempt, significand: 1)
      let ceiling = min(milliseconds(policy.maxDelay), milliseconds(policy.baseDelay) * growth)
      wait = .milliseconds(draw * ceiling)
    }
    let taken = max(wait, minimum)
    guard waited + taken <= policy.waitBudget else { return nil }
    return taken
  }

  private static func milliseconds(_ duration: Duration) -> Double {
    let (seconds, attoseconds) = duration.components
    return Double(seconds) * 1000 + Double(attoseconds) / 1e15
  }
}
