import Foundation
import GateSupport
import MountayaClient

extension PublicRunners {
  /// credentials builds the credential from its parts through the public initializer, which is
  /// where a share token replaces a key, and answers with the headers it and the case's
  /// language send to an operation declaring the case's facts, or with the class it is refused
  /// with.
  ///
  /// A share token whose case asks for the visitor's cookies, `cookie: true`, is built with a
  /// cookie source, which `Credential.share(token:cookies:)` alone takes, and every case is
  /// projected for its `method` through `headers(for:language:method:)`, since the method and the
  /// operation's declaration, `read: true` as `CredentialDeclaration.isRead`, are what tell such a
  /// token's read from its write.
  ///
  /// A session token written as a string is a `SessionToken.value`, whose user the client is not
  /// told. One written as an object is a source reporting the user its token was minted for,
  /// which is `SessionToken.minted` holding what `postSession` answered; the fixture names no
  /// expiry, and the projection reads none, so the runner gives it the epoch.
  ///
  /// A case naming a `stream` makes the stream's open in place of a request. The open is a
  /// request to the stream's operation and goes through the same projection, so the runner
  /// projects the facts the case declares, holding them to what every stream declares; the
  /// `Accept` that asks for the stream is the stream's own and is not among what the fixture
  /// compares.
  static let credentials = Runner(id: "transport.credentials", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    let parts = input["credential"] ?? .object([])
    let secretKey = try parts.optionalString(at: "secretKey")
    let publishableKey = try parts.optionalString(at: "publishableKey")
    let shareToken = try parts.optionalString(at: "shareToken")
    let asksForCookies = try parts.flag(at: "cookie")
    let sessionToken = try Self.sessionToken(parts["sessionToken"])
    let method = try input.string(at: "method")
    let actingUserText = try input.optionalString(at: "actingUser") ?? "none"
    guard let actingUser = CredentialDeclaration.ActingUser(rawValue: actingUserText) else {
      throw FixtureError(description: "no acting user is called `\(actingUserText)`")
    }
    let declaration = CredentialDeclaration(
      actingUser: actingUser,
      acceptsShareToken: try input.flag(at: "acceptsShareToken"),
      requiresSession: try input.flag(at: "requiresSession"),
      requiresSecretKey: try input.flag(at: "requiresSecretKey"),
      takesNoCredential: try input.flag(at: "takesNoCredential"),
      isRead: try input.flag(at: "read")
    )
    if let stream = try input.optionalString(at: "stream") {
      guard ["agent", "collaboration"].contains(stream) else {
        throw FixtureError(description: "no stream is called `\(stream)`")
      }
      guard declaration.requiresSession, declaration.actingUser == .required else {
        throw FixtureError(description: "a stream's open declares less than every stream does")
      }
    }

    let language = try input.optionalString(at: "language")
    guard !asksForCookies || (shareToken != nil && secretKey == nil) else {
      throw FixtureError(description: "`cookie` asks for cookies beside no share token")
    }
    do throws(MountayaError) {
      var credential = try Credential(
        secretKey: secretKey,
        publishableKey: publishableKey,
        sessionToken: sessionToken,
        shareToken: shareToken
      )
      if asksForCookies, case .share(let token, _) = credential {
        credential = .share(token: token, cookies: { _ in "visitor=7" })
      }
      let headers = try credential.headers(for: declaration, language: language, method: method)
      return .value(
        .object([
          OrderedJSON.Member(
            key: "headers",
            value: .object(
              headers.keys.sorted().map {
                OrderedJSON.Member(key: $0, value: .string(headers[$0] ?? ""))
              }
            )
          ),
          OrderedJSON.Member(key: "refused", value: .null),
        ])
      )
    } catch {
      return .value(
        .object([
          OrderedJSON.Member(key: "headers", value: .null),
          OrderedJSON.Member(key: "refused", value: .string(error.name)),
        ])
      )
    }
  }

  /// sessionToken reads a case's session token: a string, or an object holding the `token` a
  /// source holds and the `userId` it reports, null for a token minted without `user_id`.
  private static func sessionToken(_ json: OrderedJSON?) throws(FixtureError) -> SessionToken? {
    guard let json, !json.isNull else { return nil }
    if let token = json.stringValue {
      return .value(token)
    }
    guard json.members != nil, json["userId"] != nil else {
      throw FixtureError(description: "a session token is a string or a source's object")
    }
    return .minted(
      RestSchema.Session(
        expires_at: Date(timeIntervalSince1970: 0),
        user_id: try json.optionalString(at: "userId"),
        token: try json.string(at: "token")
      )
    )
  }
}
