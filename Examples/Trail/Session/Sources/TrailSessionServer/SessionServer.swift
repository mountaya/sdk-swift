import Foundation
import MountayaAdmin
import MountayaClient

/// SessionServer is what Trail's `MOUNTAYA_SESSION_URL` points at: it answers `POST /session` with
/// the `Session` its mint answers, as the JSON object the API answered under `data`, so the app's
/// `SessionTokenEngine` reads it while the secret key that minted it stays in this process.
///
/// Any other path is a 404 and any other method a 405, and a mint that fails is a 502 whose body
/// names no key and no token. `listen(port:)` serves it on the loopback address alone. It is
/// Sendable: its stored properties are constants of Sendable types.
public final class SessionServer: Sendable {
  /// Mint is what answers a session: `minting(_:publishableKey:)` over a client, or a test's own.
  public typealias Mint = @Sendable () async throws -> RestSchema.Session

  /// path is the one path the server answers.
  public static let path = "/session"

  /// port is the port it listens on by default, `localhost:8787` from the iOS simulator and
  /// `10.0.2.2:8787` from the Android emulator, which reaches the host's loopback there.
  public static let port: UInt16 = 8787

  private let mint: Mint
  private let onAnswer: (@Sendable (_ method: String, _ path: String, _ status: Int) -> Void)?
  private let onFailure: (@Sendable (any Error) -> Void)?

  /// Creates a server answering each session `mint` answers, telling `onAnswer` each request's
  /// method, path and status, never what an answer carries, and `onFailure` each mint that failed.
  public init(
    mint: @escaping Mint,
    onAnswer: (@Sendable (_ method: String, _ path: String, _ status: Int) -> Void)? = nil,
    onFailure: (@Sendable (any Error) -> Void)? = nil
  ) {
    self.mint = mint
    self.onAnswer = onAnswer
    self.onFailure = onFailure
  }

  /// minting is the mint of `mountaya`, a client under the secret key: the session `postSession`
  /// mints for `publishableKey` without `user_id`.
  public static func minting(_ mountaya: Mountaya, publishableKey: String) -> Mint {
    {
      try await mountaya.admin.sessions.postSession(
        body: AdminSchema.SessionCreateParams(publishable_key: publishableKey)
      ).data
    }
  }

  // trail: trail.session
  /// answer is the server's answer to `method` on `path`, a query left out of it: the session
  /// minted, a 404, a 405 naming the method allowed, or a 502 naming no key and no token.
  public func answer(method: String, path: String) async -> SessionAnswer {
    let path =
      path.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
      .first.map(String.init) ?? path
    let answer: SessionAnswer
    if path != Self.path {
      answer = .error(
        404, saying: "Nothing is served at \(path): POST \(Self.path) mints a session.")
    } else if method != "POST" {
      answer = .error(405, saying: "\(Self.path) answers POST alone.", allow: "POST")
    } else {
      do {
        answer = SessionAnswer(status: 200, body: try JSONEncoder().encode(try await mint()))
      } catch {
        onFailure?(error)
        answer = .error(502, saying: "The session could not be minted\(Self.reason(error)).")
      }
    }
    onAnswer?(method, path, answer.status)
    return answer
  }

  /// reason says why a mint failed, from what the client threw, and never what the API's answer
  /// carried: `: the API answered 401` or `: the API could not be reached`, or nothing.
  public static func reason(_ error: any Error) -> String {
    guard let error = error as? MountayaError else { return "" }
    switch error {
    case .api(let refusal): return ": the API answered \(refusal.status)"
    case .connection: return ": the API could not be reached"
    default: return ""
    }
  }
}

/// SessionAnswer is what the server answers one request: its status, its JSON body, and the method
/// a 405 allows.
public struct SessionAnswer: Sendable, Equatable {
  /// status is the HTTP status.
  public let status: Int
  /// body is the JSON the answer carries.
  public let body: Data
  /// allow is the `Allow` header a 405 carries, nil for every other answer.
  public let allow: String?

  /// Creates an answer.
  public init(status: Int, body: Data, allow: String? = nil) {
    self.status = status
    self.body = body
    self.allow = allow
  }

  /// error is an answer of `status` whose body is `{"error": sentence}`.
  static func error(_ status: Int, saying sentence: String, allow: String? = nil) -> SessionAnswer {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .withoutEscapingSlashes
    let body = (try? encoder.encode(["error": sentence])) ?? Data()
    return SessionAnswer(status: status, body: body, allow: allow)
  }

  /// http is the answer as HTTP/1.1 writes it, closing the connection once sent.
  var http: Data {
    var head =
      "HTTP/1.1 \(status) \(Self.reasonPhrases[status] ?? "Unknown")\r\n"
      + "Content-Type: application/json; charset=utf-8\r\n"
      + "Content-Length: \(body.count)\r\n"
      + "Cache-Control: no-store\r\n"
      + "Connection: close\r\n"
    if let allow {
      head += "Allow: \(allow)\r\n"
    }
    return Data((head + "\r\n").utf8) + body
  }

  private static let reasonPhrases = [
    200: "OK", 400: "Bad Request", 404: "Not Found", 405: "Method Not Allowed",
    413: "Content Too Large", 502: "Bad Gateway",
  ]
}
