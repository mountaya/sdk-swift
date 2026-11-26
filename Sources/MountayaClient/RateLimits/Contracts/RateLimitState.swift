/// RateLimitState is the limits an answer says it was counted against, as its `RateLimit-Policy`
/// and `RateLimit` fields describe them.
///
/// It is reported, never counted against: the client delays no request on what it says, since
/// an organization's figures are its agreement's and the API is what holds them.
public struct RateLimitState: Sendable, Hashable {
  /// policies is one policy per String member of `RateLimit-Policy`, in the order the field
  /// lists them.
  public let policies: [RateLimitPolicy]

  /// Creates a state, such as a test's stand-in for one an answer described.
  public init(policies: [RateLimitPolicy]) {
    self.policies = policies
  }
}
