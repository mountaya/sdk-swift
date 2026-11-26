/// CredentialHeaders projects a credential and the client's language onto the headers a request
/// carries, `*` for a client given no language, and refuses what an operation does not take before
/// the request leaves the process.
///
/// An event stream's open is a request to its operation, so it carries the same projection,
/// the language among it, beside the `Accept` that asks for the stream.
enum CredentialHeaders {
  static let apiKey = "X-API-Key"
  static let sessionToken = "X-Session-Token"
  static let shareToken = "X-Share-Token"
  static let acceptLanguage = "Accept-Language"
  /// anyLanguage is the language a client given none sends: RFC 9110 reads `*` as no language in
  /// particular, so the language an answer is written in is the client's configuration and never
  /// one a platform's loader writes on a request that carries none (`sdk/SPEC.md` §1).
  static let anyLanguage = "*"

  /// The prefix each kind of credential starts with, and what a reader calls it.
  private static let prefixes: [(prefix: String, name: String)] = [
    ("pk_", "a publishable key"),
    ("sk_", "a secret key"),
    ("sess_", "a session token"),
    ("share_", "a share token"),
  ]

  /// check refuses a credential with a member that is missing, that holds a character no
  /// header carries, or whose prefix is not its own, in that order and member by member: the
  /// key or the token first, then the session token beside a key.
  ///
  /// The prefix and never the length: a length check is a second copy of the server's format,
  /// and the day the format widens it refuses a key the server accepts. A refusal never quotes
  /// the value, which may be a secret.
  static func check(_ credential: Credential) throws(MountayaError) {
    switch credential {
    case .publishable(let key, let session):
      try expect(key, toStartWith: "pk_", as: "The publishable key")
      switch session {
      case .value(let token)?:
        try checkSessionToken(token)
      case .minted(let minted)?:
        try checkSessionToken(minted.token)
      case .function?, .source?, nil:
        // A token read per request is held to the same rules at that read.
        break
      }
    case .share(let token, _):
      try expect(token, toStartWith: "share_", as: "The share token")
    #if !(os(iOS) || os(tvOS) || os(watchOS) || os(visionOS))
      case .secret(let key):
        try expect(key, toStartWith: "sk_", as: "The secret key")
    #endif
    }
  }

  /// checkSessionToken refuses a session token that is missing, that no header carries, or
  /// whose prefix is not `sess_`.
  static func checkSessionToken(_ token: String) throws(MountayaError) {
    try expect(token, toStartWith: "sess_", as: "The session token")
  }

  /// checkLanguage refuses a language that is empty or whitespace alone, or that holds a
  /// character no header carries. A language left out is none, and sends `*`.
  static func checkLanguage(_ language: String?) throws(MountayaError) {
    guard let language else { return }
    guard !HeaderValue.isBlank(language) else {
      throw refusal(
        "The language is empty: pass a language tag such as `fr`, or leave the language out."
      )
    }
    guard HeaderValue.isCarried(language) else {
      throw refusal(
        "The language holds \(HeaderValue.uncarried): pass a language tag such as `fr`."
      )
    }
  }

  /// checkCookie refuses a visitor's cookie, as the credential's source answers it for a
  /// request, that holds a character no header carries: the client writes it as a `Cookie`
  /// header itself, where no browser holds the visitor's session, so it is held to the rule every
  /// header the client writes is (`sdk/SPEC.md` §1). The refusal never quotes the cookie.
  static func checkCookie(_ cookie: String) throws(MountayaError) {
    guard HeaderValue.isCarried(cookie) else {
      throw refusal(
        "The visitor's cookie holds \(HeaderValue.uncarried): answer it as the browser wrote it."
      )
    }
  }

  /// headers returns what a credential and a language send to an operation declaring
  /// `declaration`, called by `method`, or refuses them with `ConfigurationError`, reading a
  /// session token the credential reads per request as it is now.
  static func headers(
    _ credential: Credential,
    language: String?,
    for declaration: CredentialDeclaration,
    method: String = "GET"
  ) throws(MountayaError) -> [String: String] {
    try check(credential)
    try checkLanguage(language)
    var session: ResolvedSession?
    if case .publishable(_, let token?) = credential {
      session = try ResolvedSession.reading(token, snapshot: nil)
    }
    return try project(
      credential,
      session: session,
      language: language,
      for: declaration,
      isRead: isRead(method, declaring: declaration)
    ).headers
  }

  /// readMethods is the methods every request sent with is a read, whatever its operation
  /// declares, in lowercase, each compared with a method's ASCII letters folded.
  static let readMethods: Set<String> = ["get", "head", "options"]

  /// isRead is true for a read, which a share token asking for the visitor's cookies sends on the
  /// visitor's session alone: an operation declared one, as every Data API query is over its
  /// `POST`, or a request sent with `GET`, `HEAD` or `OPTIONS`, in any letter case, the ASCII
  /// letters alone folded. Every other request is a write.
  static func isRead(_ method: String, declaring declaration: CredentialDeclaration) -> Bool {
    declaration.isRead || readMethods.contains(HeaderLookup.asciiLowercase(method))
  }

  /// Projection is what a credential sends to one request. It prints the names of its headers
  /// alone, however it is printed, since their values carry the credential (`sdk/SPEC.md` §1).
  struct Projection: Sendable, CustomStringConvertible, CustomDebugStringConvertible,
    CustomReflectable
  {
    /// headers is the credential's headers and the language.
    var headers: [String: String]
    /// cookies is the source of the visitor's cookies where the request asks for them, and nil
    /// where it sends none.
    var cookies: CookieSource?

    /// description is the projection as a log may show it: its headers by name.
    var description: String {
      "Projection(headers: [\(headers.keys.sorted().joined(separator: ", "))])"
    }

    /// debugDescription is the same text, so a debugger shows no more than a log.
    var debugDescription: String {
      description
    }

    /// customMirror has no children, so `dump` prints the description rather than the values.
    var customMirror: Mirror {
      Mirror(self, children: [], displayStyle: .struct)
    }
  }

  /// project returns what a checked credential, with its session token as read for this
  /// request, and a checked language send to an operation declaring `declaration`, or refuses
  /// them with `ConfigurationError`.
  ///
  /// The operation's own declarations decide, in this order: a secret key where one does not
  /// authenticate it, and every other credential where one does; a share token where it takes a
  /// session or declares no share token; no session token where it requires one; and a session
  /// token minted without `user_id` where it acts as one. A share token that asks for the visitor's
  /// cookies sends them to every operation that takes a credential, and a read that declares no
  /// share token is sent the cookies alone, one that requires a session token included, since a
  /// session the visitor's cookie holds is plain to the server alone; `isRead` is what tells a
  /// read, by its method or its declaration (`isRead(_:declaring:)`).
  static func project(
    _ credential: Credential,
    session: ResolvedSession?,
    language: String?,
    for declaration: CredentialDeclaration,
    isRead: Bool
  ) throws(MountayaError) -> Projection {
    var headers = [acceptLanguage: language ?? anyLanguage]
    if declaration.takesNoCredential {
      return Projection(headers: headers, cookies: nil)
    }
    switch credential {
    case .publishable(let key, _):
      if declaration.requiresSecretKey {
        throw refusal(
          "This operation mints a session token, which a secret key alone authenticates, on a "
            + "server: a publishable key cannot call it."
        )
      }
      guard let session, let token = session.token else {
        if declaration.requiresSession {
          throw .configuration(
            ConfigurationError(
              message:
                "This operation requires a session token beside the publishable key, and none "
                + "is set.",
              cause: session?.mintError
            )
          )
        }
        headers[apiKey] = key
        return Projection(headers: headers, cookies: nil)
      }
      if declaration.actingUser == .required, case .known(nil) = session.user {
        throw refusal(
          "This operation acts as the user its session token was minted for, and the token was "
            + "minted without user_id: mint it with `postSession`'s `user_id` set to the user."
        )
      }
      headers[apiKey] = key
      headers[sessionToken] = token
      return Projection(headers: headers, cookies: nil)

    case .share(let token, let cookies):
      if declaration.requiresSecretKey {
        throw refusal(
          "This operation mints a session token, which a secret key alone authenticates, on a "
            + "server: a share token cannot call it."
        )
      }
      if declaration.acceptsShareToken, !declaration.requiresSession {
        headers[shareToken] = token
        return Projection(headers: headers, cookies: cookies)
      }
      if let cookies, isRead {
        // A read that takes no share token rides the visitor's own session alone, one that
        // requires a session token among them: the server judges the session the cookie holds.
        return Projection(headers: headers, cookies: cookies)
      }
      if declaration.requiresSession {
        throw refusal(
          "This operation requires a session token, which accompanies a publishable key: a "
            + "share token cannot call it."
        )
      }
      throw refusal(
        "A share token reads a shared resource and writes nothing, and this operation does not "
          + "take one."
      )

    #if !(os(iOS) || os(tvOS) || os(watchOS) || os(visionOS))
      case .secret(let key):
        guard declaration.requiresSecretKey else {
          throw refusal(
            "A secret key authenticates only the operation that mints a session token, and "
              + "the API answers it anywhere else as if no credential had been sent."
          )
        }
        headers[apiKey] = key
        return Projection(headers: headers, cookies: nil)
    #endif
    }
  }

  /// redacted returns a value as a log may show it: the credential prefix it starts with, or
  /// nothing where it starts with none, then an ellipsis. A key or a token is enough to act as its
  /// owner, so no more of one is printed, and the prefix is what tells a reader which part sits
  /// where.
  static func redacted(_ value: String) -> String {
    (prefixes.first { value.hasPrefix($0.prefix) }?.prefix ?? "") + "…"
  }

  /// redacted returns a session token as a log may show it: a token held as a value by its
  /// prefix, and one read per request by where it is read from.
  static func redacted(_ token: SessionToken) -> String {
    switch token {
    case .value(let value): redacted(value)
    case .minted(let session): redacted(session.token)
    case .function: "function"
    case .source: "source"
    }
  }

  /// refusal is the configuration error a credential is refused with.
  static func refusal(_ message: String) -> MountayaError {
    .configuration(ConfigurationError(message: message))
  }

  /// expect refuses a member that is missing, that no header carries, or whose prefix is not
  /// `prefix`, in that order, so an empty key is named as missing rather than as a wrong prefix.
  private static func expect(_ value: String, toStartWith prefix: String, as part: String)
    throws(MountayaError)
  {
    let expected = prefixes.first { $0.prefix == prefix }?.name ?? "this part"
    guard !HeaderValue.isBlank(value) else {
      throw refusal(
        "\(part) is empty or whitespace alone, which is a missing one: pass \(expected).")
    }
    guard HeaderValue.isCarried(value) else {
      throw refusal(
        "\(part) holds \(HeaderValue.uncarried): pass \(expected) as it was issued."
      )
    }
    guard !value.hasPrefix(prefix) else { return }
    var message = "\(part) starts with `\(prefix)`"
    if let found = prefixes.first(where: { value.hasPrefix($0.prefix) }) {
      message += ", and the one given starts with `\(found.prefix)`, which is \(found.name)'s"
    }
    throw refusal(message + ": pass \(expected) here.")
  }
}
