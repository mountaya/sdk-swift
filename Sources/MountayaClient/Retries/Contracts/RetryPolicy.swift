/// RetryPolicy is how many times a failed attempt is repeated, how long the waits between
/// attempts may grow, and how long a call may spend waiting in all.
///
/// A client carries one, and a call may carry its own through `RequestOptions`. Which failures
/// are repeated is the contract's and not a setting: a 429 always; a 502, 503, 504 and a request
/// that never arrived where the operation declares itself idempotent or the request carried an
/// `Idempotency-Key`; and a 409 whose key is still in use, which no ceiling of attempts counts.
public struct RetryPolicy: Sendable, Hashable {
  /// standard is the contract's: two retries after the first attempt, from a 500 ms base up to
  /// a 30 s ceiling, and 60 s of waiting in all.
  public static let standard = RetryPolicy(
    checked: 2,
    baseDelay: .milliseconds(500),
    maxDelay: .seconds(30),
    waitBudget: .seconds(60)
  )

  /// maxRetries is how many attempts may follow the first. Zero repeats nothing, but a 409 whose
  /// key is still in use, which asks whether the first attempt has finished and is counted
  /// against no ceiling.
  public let maxRetries: Int
  /// baseDelay is the ceiling of the first wait, which doubles with each attempt after it.
  public let baseDelay: Duration
  /// maxDelay is the ceiling no wait's schedule grows past. A `Retry-After` the server sends is
  /// not held to it.
  public let maxDelay: Duration
  /// waitBudget is how long the waits of one call may last together. A wait that does not fit
  /// what the waits before it left is not taken, and the attempt settles with the error its
  /// answer maps to.
  public let waitBudget: Duration

  /// Creates a policy, each value left out being the contract's.
  ///
  /// It throws `ConfigurationError` for a negative count, a negative delay or a negative
  /// budget, which no schedule can follow.
  public init(
    maxRetries: Int = 2,
    baseDelay: Duration = .milliseconds(500),
    maxDelay: Duration = .seconds(30),
    waitBudget: Duration = .seconds(60)
  ) throws(MountayaError) {
    guard maxRetries >= 0 else {
      throw .configuration(
        ConfigurationError(message: "A retry policy repeats zero or more times, never fewer.")
      )
    }
    guard baseDelay >= .zero, maxDelay >= .zero else {
      throw .configuration(
        ConfigurationError(message: "A retry policy waits zero or more, never a negative delay.")
      )
    }
    guard waitBudget >= .zero else {
      throw .configuration(
        ConfigurationError(message: "A retry policy's wait budget is zero or more, never negative.")
      )
    }
    self.init(checked: maxRetries, baseDelay: baseDelay, maxDelay: maxDelay, waitBudget: waitBudget)
  }

  private init(
    checked maxRetries: Int, baseDelay: Duration, maxDelay: Duration, waitBudget: Duration
  ) {
    self.maxRetries = maxRetries
    self.baseDelay = baseDelay
    self.maxDelay = maxDelay
    self.waitBudget = waitBudget
  }
}
