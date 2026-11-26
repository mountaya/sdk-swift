/// RateLimitPolicy is one limit an answer was counted against: its quota and window from
/// `RateLimit-Policy`, and what is left of it and when it resets from `RateLimit`.
///
/// A name is the API's to add, so one this build has never seen is read like the others:
/// `minute`, `month`, `address`, `member`, `studio-embedded` and `share` today.
public struct RateLimitPolicy: Sendable, Hashable {
  /// name is the policy's name, such as `minute`.
  public let name: String
  /// quota is how much the window allows.
  public let quota: Int64
  /// window is how long the window lasts, or nil where the answer states none.
  public let window: Duration?
  /// remaining is what is left of the quota, or nil where the answer states none.
  public let remaining: Int64?
  /// reset is how long until the window resets, or nil where the answer states none.
  public let reset: Duration?

  /// Creates a policy, such as a test's stand-in for one an answer described.
  public init(
    name: String,
    quota: Int64,
    window: Duration? = nil,
    remaining: Int64? = nil,
    reset: Duration? = nil
  ) {
    self.name = name
    self.quota = quota
    self.window = window
    self.remaining = remaining
    self.reset = reset
  }
}
