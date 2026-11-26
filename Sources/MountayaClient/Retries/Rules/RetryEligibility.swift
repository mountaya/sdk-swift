/// RetryEligibility decides whether a failed attempt is repeated.
///
/// Only 409, 429, 502, 503 and 504 are, a 409 only where its entry is coded
/// `IDEMPOTENCY_KEY_IN_USE`, and a 429 only where its entry is not coded `LIMIT_REACHED`. Every
/// other 4xx is a statement about the request itself, which a repeat would answer identically
/// while spending a limit, and a 412 in particular is its caller's to settle.
enum RetryEligibility {
  /// The statuses repeated only where a repeat is safe, since they do not say whether the
  /// request had an effect.
  private static let repeatedWhenSafe: Set<Int> = [502, 503, 504]

  /// allowsRetry tells whether the attempt numbered `attempt`, counting the first as zero, is
  /// followed by another, before the wait its answer names is held to the call's budget.
  ///
  /// A 429 coded `LIMIT_REACHED` is never repeated, whatever the operation declares and
  /// whatever the attempts left: it refuses a ceiling, a count of something held that lifts when
  /// something is freed or the arrangement changes and never by waiting, so it names no wait.
  /// Any other 429 is always repeated, since the API has said it did nothing. A 502, 503 or 504,
  /// and a failure with no status at all, are repeated where the operation declares itself
  /// idempotent or the request carried a key (`keyed`): a dropped socket does not say whether a
  /// write landed, and a key is what makes asking again safe. A 409 whose first entry is coded
  /// `IDEMPOTENCY_KEY_IN_USE` is repeated where the request carried a key, and is counted
  /// against no ceiling of attempts, since it asks whether the first attempt has finished
  /// rather than sending the write again. Nothing else is repeated past `maxRetries`.
  static func allowsRetry(
    after attempt: Int,
    status: Int?,
    code: APIErrorCode?,
    idempotent: Bool,
    keyed: Bool,
    policy: RetryPolicy
  ) -> Bool {
    if status == 409 {
      return keyed && code == .idempotencyKeyInUse
    }
    if status == 429 && code == .limitReached {
      return false
    }
    guard attempt < policy.maxRetries else { return false }
    guard let status else { return idempotent || keyed }
    return status == 429 || ((idempotent || keyed) && repeatedWhenSafe.contains(status))
  }
}
