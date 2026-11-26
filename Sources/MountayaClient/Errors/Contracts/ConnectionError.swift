/// ConnectionError is a request that never arrived, so no status answered it: a dropped
/// connection, or an attempt that spent its time budget.
///
/// A cancelled call is not one: it throws `CancellationError`, since a connection error is
/// retried and a retry after the caller left is a request nobody is waiting for. No request id
/// rides one, since no answer came, and the client never makes one up.
public struct ConnectionError: Sendable, CustomStringConvertible {
  /// idempotencyKey is the `Idempotency-Key` the call sent, or nil where it sent none: an answer
  /// that never came does not say the write was not made.
  public let idempotencyKey: String?
  /// cause is the platform's own failure, for diagnostics only: a caller never matches on it.
  public let cause: (any Error)?

  /// Creates the failure of a request that never arrived.
  public init(idempotencyKey: String? = nil, cause: (any Error)? = nil) {
    self.idempotencyKey = idempotencyKey
    self.cause = cause
  }

  /// message says what failed, the text `sdk-kotlin` and `sdk-dart` give theirs: the request never
  /// arrived.
  public var message: String {
    "the request never arrived"
  }

  /// description is the failure as a developer reads it in a log, its `message`.
  public var description: String {
    message
  }
}
