/// RequestOptions is what one call sets for itself, apart from what it sends.
///
/// Every generated method ends with `options:`, so a setting added here reaches every call at
/// once and changes no call site.
public struct RequestOptions: Sendable, Hashable {
  /// retry is the call's own retry policy, its wait budget among it, or nil where the call
  /// follows its client's.
  public var retry: RetryPolicy?
  /// timeout is the call's own budget for each of its attempts, or nil where the call takes the
  /// larger of its client's and the operation's own. A budget the call names is the attempt's,
  /// shorter or longer than the API's.
  public var timeout: Duration?

  /// Creates options, each one left out deferring to the client.
  public init(retry: RetryPolicy? = nil, timeout: Duration? = nil) {
    self.retry = retry
    self.timeout = timeout
  }
}
