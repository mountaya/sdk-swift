import Foundation

/// AnswerError builds the error an answer raises: the row its status and code fall on, and
/// everything the contract has an error carry off the answer.
enum AnswerError {
  /// Header names the answer is read for.
  static let requestIdHeader = "X-Request-Id"
  static let retryAfterHeader = "Retry-After"
  static let etagHeader = "ETag"
  static let rateLimitPolicyHeader = "RateLimit-Policy"
  static let rateLimitHeader = "RateLimit"

  /// error returns the error an answer of `status` with these headers and this read body raises.
  ///
  /// The wait a `Retry-After` names is carried in whole seconds, an HTTP date read against `now`
  /// and rounded up, so that a caller who schedules from it never comes back early, and it is
  /// counted from `now`, the instant the answer arrived, where the error names when it ends. What
  /// the call's operation declares, `declaration`, sharpens the next step its description names.
  static func error(
    status: Int,
    headers: [String: String],
    envelope: ErrorEnvelope.Read,
    now: Date,
    idempotencyKey: String?,
    declaration: NextStep.Declaration = .none
  ) -> APIError {
    let folded = HeaderLookup.folded(headers)
    return APIError(
      kind: ErrorLadder.kind(status: status, code: envelope.errors.first?.code),
      status: status,
      errors: envelope.errors,
      metadata: envelope.metadata,
      retryAfter: retryAfter(inFolded: folded, now: now),
      requestId: HeaderLookup.value(of: requestIdHeader, inFolded: folded),
      rateLimit: rateLimit(inFolded: folded),
      etag: HeaderLookup.value(of: etagHeader, inFolded: folded),
      idempotencyKey: idempotencyKey,
      answeredAt: now,
      declaration: declaration
    )
  }

  /// retryAfter returns the whole seconds an answer's `Retry-After` names, an HTTP date's distance
  /// rounded up, which is the wait the transport takes before it asks again, or nil where it names
  /// none the client can read. It is kept out of line, so the transport's loop, printed once for
  /// each operation's result, carries a call rather than the fold and the read.
  @inline(never)
  static func retryAfter(in headers: [String: String], now: Date) -> Duration? {
    retryAfter(inFolded: HeaderLookup.folded(headers), now: now)
  }

  /// rateLimit returns the state an answer's headers describe, or nil where they describe none.
  static func rateLimit(in headers: [String: String]) -> RateLimitState? {
    rateLimit(inFolded: HeaderLookup.folded(headers))
  }

  /// retryAfter reads `Retry-After` off headers `HeaderLookup.folded(_:)` folded.
  private static func retryAfter(inFolded folded: [String: String], now: Date) -> Duration? {
    HeaderLookup.value(of: retryAfterHeader, inFolded: folded).flatMap {
      RetryAfter.delay(header: $0, now: now)
    }
  }

  /// rateLimit reads the rate limit's headers off headers `HeaderLookup.folded(_:)` folded.
  private static func rateLimit(inFolded folded: [String: String]) -> RateLimitState? {
    RateLimitHeaders.state(
      policy: HeaderLookup.value(of: rateLimitPolicyHeader, inFolded: folded),
      remaining: HeaderLookup.value(of: rateLimitHeader, inFolded: folded)
    )
  }
}
