import Foundation

/// Credential is what the client authenticates its requests with, one case per shape the
/// contract allows.
///
/// A session token accompanies a publishable key, so it rides on `.publishable`, and a share
/// token replaces a key, so `.share` has nothing beside it: a combination the server would
/// misread cannot be built. Each value is checked by its prefix, never its length, before any
/// request carrying it leaves the process.
public enum Credential: Sendable {
  /// publishable is a publishable key (`pk_`), which is safe to ship in an app, and the session
  /// token (`sess_`) that accompanies it, where it has one.
  ///
  /// The user an operation acts as is the one the session token was minted for: no header
  /// names one.
  case publishable(key: String, sessionToken: SessionToken? = nil)

  /// secret is a secret key (`sk_`), which mints session tokens and belongs on a server.
  ///
  /// It is unavailable on every app platform, so an app cannot ship one by accident. macOS and
  /// Linux keep it, since servers run there.
  @available(iOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(tvOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(watchOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(visionOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(
    macCatalyst, unavailable, message: "A secret key belongs on a server, never in an app."
  )
  case secret(key: String)

  /// share is a share-link visitor's token (`share_`), which reads a shared resource and
  /// writes nothing, and where the visitor's own session should ride beside it, the source of
  /// their cookies.
  ///
  /// No cookie is ambient: one is sent only where `cookies` is given, as the `Cookie` it answers
  /// for each request, and never to an operation that takes no credential. A read that takes no
  /// share token rides the visitor's session alone, with no `X-Share-Token`, and a write under
  /// such a token is refused, as every write under a share token is.
  case share(token: String, cookies: CookieSource? = nil)

  /// Creates the credential separate parts make, such as a key read from configuration and a
  /// share token read from a link.
  ///
  /// A share token replaces the key, so where one is given it is the whole credential and the
  /// other parts are not sent. Otherwise the publishable key carries the session token beside
  /// it. It throws `ConfigurationError` where the parts make no credential, or where a part is
  /// missing, has the wrong prefix or holds a character no header carries.
  public init(
    publishableKey: String? = nil,
    sessionToken: SessionToken? = nil,
    shareToken: String? = nil
  ) throws(MountayaError) {
    if let shareToken {
      self = .share(token: shareToken)
    } else if let publishableKey {
      self = .publishable(key: publishableKey, sessionToken: sessionToken)
    } else if sessionToken != nil {
      throw CredentialHeaders.refusal(
        "A session token accompanies a publishable key, and is refused alone: pass the "
          + "publishable key beside it."
      )
    } else {
      throw CredentialHeaders.refusal("No credential: pass a publishable key or a share token.")
    }
    try CredentialHeaders.check(self)
  }

  /// Creates the credential separate parts make, where one of them may be a secret key.
  ///
  /// A secret key is sent alone, so it is refused beside any other part. Without one, this is
  /// the initializer that takes no secret key.
  @available(iOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(tvOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(watchOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(visionOS, unavailable, message: "A secret key belongs on a server, never in an app.")
  @available(
    macCatalyst, unavailable, message: "A secret key belongs on a server, never in an app."
  )
  public init(
    secretKey: String?,
    publishableKey: String? = nil,
    sessionToken: SessionToken? = nil,
    shareToken: String? = nil
  ) throws(MountayaError) {
    guard let secretKey else {
      try self.init(
        publishableKey: publishableKey,
        sessionToken: sessionToken,
        shareToken: shareToken
      )
      return
    }
    guard publishableKey == nil, sessionToken == nil, shareToken == nil else {
      throw CredentialHeaders.refusal(
        "A secret key is sent alone: pass no other part beside it."
      )
    }
    self = .secret(key: secretKey)
    try CredentialHeaders.check(self)
  }

  /// headers returns the headers this credential and the client's language send to an operation
  /// that declares what `declaration` says, called by `method`, the HTTP method, `GET` unless the
  /// caller names another, on a request and on an event stream's open alike, or throws
  /// `ConfigurationError` where the operation does not take them.
  ///
  /// The refusals are the server's own answers, given before the request leaves: a secret key
  /// anywhere but the operation it authenticates, a share token where the operation takes
  /// none, a missing session token where the operation requires one, and a token minted without
  /// `user_id` where the operation acts as one. An operation that takes no credential is sent none
  /// and refuses none, and is sent the language all the same, `*` where `language` is nil, which
  /// asks for no language in particular. A credential or a language that is missing, or holds a
  /// character outside printable ASCII, is refused whatever the operation.
  ///
  /// The method matters to a share token that asks for the visitor's cookies alone: a read, an
  /// operation the declaration says is one or a call by `GET`, `HEAD` or `OPTIONS` in any letter
  /// case, is sent on the visitor's session with no `X-Share-Token`, and any other call is a write,
  /// refused as every write under a share token is.
  public func headers(
    for declaration: CredentialDeclaration,
    language: String? = nil,
    method: String = "GET"
  ) throws(MountayaError) -> [String: String] {
    try CredentialHeaders.headers(self, language: language, for: declaration, method: method)
  }
}

/// CookieSource answers the `Cookie` header a request to `url` carries for a share-link visitor,
/// read from wherever the application keeps the visitor's web session, or nil for none.
///
/// It is synchronous, since a map's request hook cannot await, and it is read for each request.
public typealias CookieSource = @Sendable (URL) -> String?

/// A credential prints each key and token by its prefix alone, however it is printed: in a
/// string, in a debugger's description, or through `dump`. A key or a token is enough to act as
/// its owner, and a credential is the value a developer is most likely to log while setting a
/// client up.
extension Credential: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
  /// description is the credential as a log may show it.
  public var description: String {
    switch self {
    case .publishable(let key, let sessionToken):
      var parts = ["key: \(CredentialHeaders.redacted(key))"]
      if let sessionToken {
        parts.append("sessionToken: \(CredentialHeaders.redacted(sessionToken))")
      }
      return "Credential.publishable(\(parts.joined(separator: ", ")))"
    case .share(let token, let cookies):
      let source = cookies == nil ? "" : ", cookies: …"
      return "Credential.share(token: \(CredentialHeaders.redacted(token))\(source))"
    #if !(os(iOS) || os(tvOS) || os(watchOS) || os(visionOS))
      case .secret(let key):
        return "Credential.secret(key: \(CredentialHeaders.redacted(key)))"
    #endif
    }
  }

  /// debugDescription is the same redacted text, so a debugger shows no more than a log.
  public var debugDescription: String {
    description
  }

  /// customMirror has no children, so `dump` and a debugger's variable view print the redacted
  /// description rather than the associated values.
  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .enum)
  }
}
