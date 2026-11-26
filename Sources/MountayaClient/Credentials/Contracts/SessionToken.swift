/// SessionToken is the session token a publishable key carries, and what the client is told of
/// the user it was minted for.
///
/// The user an operation acts as is the one its session token was minted for, and no header
/// names one. A token whose user the client is told lets an operation that requires a user be
/// refused locally under a token naming none, where the API would answer it with a 401 that
/// names no rule; a token whose user the client is not told is sent for the API to decide.
///
/// A token is read for every request, so a refreshed one reaches the next request without
/// rebuilding the client.
public enum SessionToken: Sendable, ExpressibleByStringLiteral {
  /// value is a token whose user the client is not told.
  case value(String)
  /// minted is a token as `postSession` answered it, naming the user it was minted for at
  /// `user_id`, or no user where that is nil.
  case minted(RestSchema.Session)
  /// function is read for every request and answers the token to send, or nil for none, in which
  /// case the request goes out under the key alone. It is synchronous, since a map's request
  /// hook cannot await, and a token it answers is held to a token's rules at that read. It
  /// does not tell the client whom it names.
  case function(@Sendable () -> String?)
  /// source is a source that keeps a token and tells of each change, such as a
  /// `SessionTokenEngine`: a request made while it holds no token and reports one on its way
  /// waits for it, and the user its snapshot names decides what an operation acting as a user
  /// refuses.
  case source(any SessionTokenSource)

  /// Creates a token whose user the client is not told, from a string literal.
  public init(stringLiteral value: String) {
    self = .value(value)
  }

  /// token is the token a request sent now would carry, or nil where there is none: a function's
  /// answer, or a source's snapshot, read afresh.
  public var token: String? {
    switch self {
    case .value(let token): token
    case .minted(let session): session.token
    case .function(let read): read()
    case .source(let source): source.snapshot.token
    }
  }
}

/// A session token prints by its prefix alone, as a credential does, however it is printed.
extension SessionToken: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
  /// description is the token as a log may show it.
  public var description: String {
    switch self {
    case .value(let token): "SessionToken.value(\(CredentialHeaders.redacted(token)))"
    case .minted(let session): "SessionToken.minted(\(CredentialHeaders.redacted(session.token)))"
    case .function: "SessionToken.function"
    case .source: "SessionToken.source"
    }
  }

  /// debugDescription is the same redacted text, so a debugger shows no more than a log.
  public var debugDescription: String {
    description
  }

  /// customMirror has no children, so `dump` and a debugger's variable view print the redacted
  /// description rather than the token.
  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .enum)
  }
}
