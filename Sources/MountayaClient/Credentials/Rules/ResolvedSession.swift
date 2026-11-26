/// ResolvedSession is a publishable key's session token as one request reads it: the token, what
/// the client is told of its user, and the failure of the mint that left none.
struct ResolvedSession: Sendable {
  /// User is what the client is told of the user a token was minted for.
  enum User: Sendable {
    /// unknown is a token whose user the client is not told: a value or a function's answer.
    case unknown
    /// known is the user a minted token or a source names, nil being none.
    case known(String?)
  }

  /// token is the token the request carries, or nil where it carries none.
  let token: String?
  let user: User
  /// mintError is the failure of the last mint where a source holds no token for it.
  let mintError: (any Error)?

  /// reading returns a token as a request reads it now: a value as it is, a function by calling
  /// it, and a source by `snapshot`, or by its own snapshot where none is given.
  ///
  /// A token a function answers or a source holds is held to a token's rules at this read, and
  /// refused with `ConfigurationError` where it breaks one; a function answering none, or a source
  /// holding none, is a request under the key alone.
  static func reading(_ token: SessionToken, snapshot: SessionSnapshot?) throws(MountayaError)
    -> ResolvedSession
  {
    switch token {
    case .value(let value):
      return ResolvedSession(token: value, user: .unknown, mintError: nil)
    case .minted(let session):
      return ResolvedSession(token: session.token, user: .known(session.user_id), mintError: nil)
    case .function(let read):
      guard let value = read() else {
        return ResolvedSession(token: nil, user: .unknown, mintError: nil)
      }
      try CredentialHeaders.checkSessionToken(value)
      return ResolvedSession(token: value, user: .unknown, mintError: nil)
    case .source(let source):
      let read = snapshot ?? source.snapshot
      guard let value = read.token else {
        return ResolvedSession(token: nil, user: .known(nil), mintError: read.error)
      }
      try CredentialHeaders.checkSessionToken(value)
      return ResolvedSession(token: value, user: .known(read.userId), mintError: nil)
    }
  }

  /// awaitingFirstToken returns the snapshot a request goes out with: the source's own where it
  /// holds a token or reports none on its way, and otherwise the first one that does, read off
  /// its subscription.
  ///
  /// The wait is bounded by the calling task: a task cancelled while it waits throws
  /// `CancellationError`, and never goes out under a snapshot that holds no token yet, which a
  /// request that needs one would refuse as a mistake of the caller's.
  static func awaitingFirstToken(from source: any SessionTokenSource) async throws
    -> SessionSnapshot
  {
    let now = source.snapshot
    guard now.token == nil, now.isMinting else { return now }
    for await snapshot in source.subscribe() where snapshot.token != nil || !snapshot.isMinting {
      return snapshot
    }
    // The subscription ends as the task is cancelled, which ends the request there.
    try Task.checkCancellation()
    return source.snapshot
  }
}

/// A session as a request reads it prints its token by its prefix alone, however it is printed, as
/// a credential does: a token is enough to act as its user (`sdk/SPEC.md` §1).
extension ResolvedSession: CustomStringConvertible, CustomDebugStringConvertible,
  CustomReflectable
{
  /// description is the session as a log may show it.
  var description: String {
    "ResolvedSession(token: \(token.map(CredentialHeaders.redacted) ?? "nil"))"
  }

  /// debugDescription is the same redacted text, so a debugger shows no more than a log.
  var debugDescription: String {
    description
  }

  /// customMirror has no children, so `dump` prints the redacted description.
  var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .struct)
  }
}
