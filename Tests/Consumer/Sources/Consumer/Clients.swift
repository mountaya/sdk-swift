import Foundation
import MountayaClient

/// Clients builds a client the ways an app and a server do: every credential shape, every
/// option, and every seam, each from the public surface alone.
enum Clients {
  /// app is a client as an app builds one: a publishable key and a session its own backend mints.
  static func app(engine: SessionTokenEngine) throws -> Mountaya {
    try Mountaya(
      credential: .publishable(key: "pk_live_a", sessionToken: .source(engine)),
      language: "fr-CH, fr;q=0.9",
      baseUrls: BaseURLs(rest: URL(fileURLWithPath: "/"), tiles: BaseURLs.standard.tiles),
      retry: try RetryPolicy(
        maxRetries: 1, baseDelay: .milliseconds(250), waitBudget: .seconds(10)),
      timeout: .seconds(20),
      onResponse: { report in
        _ = (report.operationId, report.surface, report.status, report.attempt, report.isReplayed)
        _ = report.requestId
        for policy in report.rateLimit?.policies ?? [] {
          _ = (policy.name, policy.quota, policy.window, policy.remaining, policy.reset)
        }
      }
    )
  }

  /// engine is a session engine over an app's own endpoint, which answers what `postSession`
  /// answers.
  static func engine() -> SessionTokenEngine {
    let engine = SessionTokenEngine {
      RestSchema.Session(
        expires_at: Date(timeIntervalSince1970: 0), user_id: "us_a", token: "sess_a")
    }
    engine.mint = { RestSchema.Session(expires_at: .distantFuture, user_id: nil, token: "sess_b") }
    engine.refresh()
    engine.disable()
    engine.enable()
    let snapshot = engine.snapshot
    _ = (snapshot.token, snapshot.expiresAt, snapshot.userId, snapshot.isMinting, snapshot.error)
    _ = engine.subscribe()
    return engine
  }

  /// tokens is every way a session token is given.
  static func tokens(engine: SessionTokenEngine) -> [SessionToken] {
    [
      "sess_a",
      .value("sess_a"),
      .minted(RestSchema.Session(expires_at: .distantFuture, user_id: "us_a", token: "sess_a")),
      .function { "sess_a" },
      .source(engine),
    ]
  }

  /// visitor is a client under a share token, the visitor's own cookies riding its reads.
  static func visitor() throws -> Mountaya {
    try Mountaya(credential: .share(token: "share_0a", cookies: { _ in "visitor=v1" }))
  }

  /// fromParts is a credential an app assembles from its configuration and a link, the share
  /// token winning over the key beside it.
  static func fromParts(shareToken: String?) throws -> Credential {
    try Credential(publishableKey: "pk_live_a", sessionToken: "sess_a", shareToken: shareToken)
  }

  #if os(macOS) || os(Linux)
    /// server is a client as a server builds one, under a secret key, which no app platform
    /// can name.
    static func server() throws -> Mountaya {
      _ = try Credential(secretKey: "sk_live_a")
      return try Mountaya(credential: .secret(key: "sk_live_a"))
    }
  #endif

  /// scripted is a client whose every seam is the consumer's own, as its tests build one.
  static func scripted() throws -> Mountaya {
    try Mountaya(
      credential: .publishable(key: "pk_test_a"),
      exchange: Recorded(wrapping: SystemExchange()),
      clock: ContinuousClock(),
      random: Draws(),
      wallClock: Pinned(now: Date(timeIntervalSince1970: 1_800_000_000))
    )
  }

  /// scriptedEngine is a session engine whose waits and wall clock are the consumer's own, so
  /// its tests hold the refresh schedule to them.
  static func scriptedEngine() -> SessionTokenEngine {
    SessionTokenEngine(
      mint: { RestSchema.Session(expires_at: .distantFuture, user_id: nil, token: "sess_a") },
      clock: ContinuousClock(),
      wallClock: Pinned(now: Date(timeIntervalSince1970: 1_800_000_000))
    )
  }

  /// headers is what a credential sends for an operation, as a map's own request hook reads it.
  static func headers(for credential: Credential) throws -> [String: String] {
    try credential.headers(
      for: CredentialDeclaration(
        actingUser: .optional,
        acceptsShareToken: true,
        requiresSession: false,
        requiresSecretKey: false,
        takesNoCredential: false,
        pendingInvitee: false
      ),
      language: "fr"
    ).merging(try credential.headers(for: CredentialDeclaration(), method: "HEAD")) { $1 }
  }
}
