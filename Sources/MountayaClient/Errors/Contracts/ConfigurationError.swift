/// ConfigurationError is a client or a call set up wrong, refused before any request left the
/// process: a credential with the wrong prefix, or one the operation does not take.
///
/// The server would answer most of these with a 401 or a 400 that names no rule. The local
/// refusal names it.
public struct ConfigurationError: Sendable, CustomStringConvertible {
  /// message says what is wrong, and what would be right, for the developer who set it up.
  public let message: String
  /// idempotencyKey is the `Idempotency-Key` the call was fixed to before it was refused, such as
  /// one refused between two attempts, or nil where it has none.
  public let idempotencyKey: String?
  /// cause is what made the refusal, such as the failed mint of a session token an operation
  /// requires, or nil where nothing beneath it failed.
  public let cause: (any Error)?

  /// Creates a refusal.
  public init(message: String, idempotencyKey: String? = nil, cause: (any Error)? = nil) {
    self.message = message
    self.idempotencyKey = idempotencyKey
    self.cause = cause
  }

  /// description is the failure as a developer reads it in a log.
  public var description: String {
    message
  }
}
