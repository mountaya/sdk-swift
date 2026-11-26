/// ResponseReport is what a client's `onResponse` hook is told of one attempt an answer came
/// back to.
///
/// An attempt that never arrived has no answer to report. The hook is told of every other one,
/// a failure and an attempt that is repeated included, and nothing it does changes what the call
/// answers.
public struct ResponseReport: Sendable, Hashable {
  /// operationId is the contract's name for the operation the attempt called.
  public let operationId: String
  /// surface is the surface the operation belongs to.
  public let surface: Surface
  /// status is the status the answer arrived with.
  public let status: Int
  /// attempt is which attempt of the call the answer came back to, zero for the first.
  public let attempt: Int
  /// isReplayed is true where the answer is one the API kept for a key it had seen and gave
  /// again, which `Idempotent-Replayed: true` says.
  public let isReplayed: Bool
  /// requestId is the answer's `X-Request-Id` exactly as sent, or nil where it sent none.
  public let requestId: String?
  /// rateLimit is the state the answer's headers describe, or nil where they describe none.
  public let rateLimit: RateLimitState?

  /// Creates a report, such as a test's stand-in for one a client made.
  public init(
    operationId: String,
    surface: Surface,
    status: Int,
    attempt: Int,
    isReplayed: Bool = false,
    requestId: String? = nil,
    rateLimit: RateLimitState? = nil
  ) {
    self.operationId = operationId
    self.surface = surface
    self.status = status
    self.attempt = attempt
    self.isReplayed = isReplayed
    self.requestId = requestId
    self.rateLimit = rateLimit
  }
}
