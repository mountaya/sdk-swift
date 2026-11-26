import Foundation
import MountayaAdmin
import MountayaClient
import Testing
import TrailSessionServer

/// publishable is a publishable key's stand-in, never shaped as one: the scenario gate refuses a
/// key under Examples/.
private let publishable = "pk_trail_test"
/// secret is a secret key's stand-in, never shaped as one, for the same reason.
private let secret = "sk_trail_test"
/// token is a session token's stand-in, never shaped as one, for the same reason.
private let token = "sess_trail_test"

/// json is an answer of `status` carrying `body`.
private func json(_ status: Int, body: String) -> ExchangeResponse {
  ExchangeResponse(
    status: status, headers: ["Content-Type": "application/json"],
    body: ExchangeBody(Data(body.utf8)))
}

/// The session server over the SDK's stub transport: an `HTTPExchange` of the test's own answers
/// every request the client makes, so nothing reaches the network and no live key is needed, while
/// the server answers on the loopback address, at a port the system picks.
@Suite("Session server")
struct SessionServerTests {

  /// Answered is the stub transport: it records each request the client sends and answers it.
  final class Answered: HTTPExchange {
    private let answer: @Sendable (ExchangeRequest) -> ExchangeResponse
    private let sent = Sent()

    init(_ answer: @escaping @Sendable (ExchangeRequest) -> ExchangeResponse) {
      self.answer = answer
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      await sent.append(request)
      return answer(request)
    }

    /// requests is every request the client sent through it.
    var requests: [ExchangeRequest] {
      get async { await sent.requests }
    }
  }

  actor Sent {
    var requests: [ExchangeRequest] = []

    func append(_ request: ExchangeRequest) {
      requests.append(request)
    }
  }

  actor Failures {
    var told: [String] = []

    func append(_ failure: String) {
      told.append(failure)
    }
  }

  /// serve listens with a server minting under a client whose every request `exchange` answers,
  /// and runs `body` with the address it listens at, closing it after.
  static func serve(
    _ exchange: Answered, failures: Failures = Failures(),
    body: (URL) async throws -> Void
  ) async throws {
    let mountaya = try Mountaya(
      credential: .secret(key: secret), retry: try RetryPolicy(maxRetries: 0), exchange: exchange)
    let server = SessionServer(
      mint: SessionServer.minting(mountaya, publishableKey: publishable),
      onFailure: { error in Task { await failures.append(SessionServer.reason(error)) } })
    let listener = try await server.listen(port: 0)
    defer { listener.cancel() }
    let address = try #require(URL(string: "http://127.0.0.1:\(listener.port)"))
    try await body(address)
  }

  /// call sends `method` to `path` at `address`, as the app's mint does, and answers the status,
  /// the headers and the body.
  static func call(_ method: String, path: String, at address: URL) async throws
    -> (status: Int, headers: [AnyHashable: Any], body: Data)
  {
    var request = URLRequest(url: address.appendingPathComponent(path))
    request.httpMethod = method
    if method == "POST" || method == "PUT" {
      request.httpBody = Data("{}".utf8)
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    let session = URLSession(configuration: .ephemeral)
    defer { session.invalidateAndCancel() }
    let (body, response) = try await session.data(for: request)
    let answered = try #require(response as? HTTPURLResponse)
    return (answered.statusCode, answered.allHeaderFields, body)
  }

  @Test("a POST to /session answers the session minted for the publishable key without user_id")
  func answersTheSession() async throws {
    let exchange = Answered { _ in
      json(
        200,
        body:
          #"{"data": {"expires_at": "2026-11-23T18:00:00.000Z", "token": "\#(token)", "user_id": null}}"#
      )
    }

    try await Self.serve(exchange) { address in
      let answer = try await Self.call("POST", path: "/session", at: address)

      #expect(answer.status == 200, "\(String(decoding: answer.body, as: UTF8.self))")
      #expect(
        answer.headers["Content-Type"] as? String == "application/json; charset=utf-8")
      // What the app's mint reads: the `Session` object itself, every member stated.
      let session = try JSONDecoder().decode(RestSchema.Session.self, from: answer.body)
      #expect(session.token == token)
      #expect(session.user_id == nil)
      #expect(session.expires_at == Date(timeIntervalSince1970: 1_795_456_800))
      let object = try JSONSerialization.jsonObject(with: answer.body)
      let members = try #require(object as? [String: Any])
      #expect(Set(members.keys) == ["expires_at", "token", "user_id"])
      #expect(members["user_id"] is NSNull)
    }

    let requests = await exchange.requests
    let minted = try #require(requests.first)
    #expect(requests.count == 1)
    #expect(minted.method == "POST")
    #expect(minted.url.path == "/v1/sessions")
    #expect(minted.header("X-API-Key") == secret, "the mint is the secret key's")
    let body = try JSONSerialization.jsonObject(with: minted.body ?? Data())
    let asked = try #require(body as? [String: Any])
    #expect(asked["publishable_key"] as? String == publishable)
    #expect(asked["user_id"] == nil, "the session is minted without user_id")
  }

  @Test("any other path is a 404 and any other method a 405, and neither mints")
  func refusesOtherRequests() async throws {
    let exchange = Answered { _ in json(500, body: "{}") }

    try await Self.serve(exchange) { address in
      #expect(try await Self.call("POST", path: "/sessions", at: address).status == 404)
      #expect(try await Self.call("GET", path: "/", at: address).status == 404)
      let get = try await Self.call("GET", path: "/session", at: address)
      #expect(get.status == 405)
      #expect(get.headers["Allow"] as? String == "POST")
      #expect(try await Self.call("PUT", path: "/session", at: address).status == 405)
      #expect(try await Self.call("POST", path: "/session/extra", at: address).status == 404)
    }

    #expect(await exchange.requests.isEmpty)
  }

  @Test("a failed mint is a 502 whose body names no key and no token")
  func failedMint() async throws {
    let exchange = Answered { _ in
      json(
        401,
        body:
          #"{"error": {"type": "authentication_error", "message": "\#(secret) \#(token) \#(publishable)"}}"#
      )
    }
    let failures = Failures()

    try await Self.serve(exchange, failures: failures) { address in
      let answer = try await Self.call("POST", path: "/session", at: address)
      let text = String(decoding: answer.body, as: UTF8.self)

      #expect(answer.status == 502, "\(text)")
      let object = try JSONSerialization.jsonObject(with: answer.body)
      let said = try #require(object as? [String: String])
      #expect(said == ["error": "The session could not be minted: the API answered 401."])
      for leak in [publishable, secret, token, "pk_", "sk_", "sess_"] {
        #expect(!text.contains(leak), "\(leak) in \(text)")
      }
    }

    #expect(await exchange.requests.count == 1)
    // The failure is told to the server's own log, by its reason alone.
    for _ in 0..<100 where await failures.told.isEmpty {
      await Task.yield()
    }
    #expect(await failures.told == [": the API answered 401"])
  }

  @Test("without either key the server refuses to start, in one sentence naming the missing one")
  func refusesWithoutKeys() throws {
    let found = try SessionKeys.read([
      "MOUNTAYA_PUBLISHABLE_KEY": publishable, "MOUNTAYA_SECRET_KEY": secret,
    ])
    #expect(found.publishableKey == publishable)
    #expect(found.secretKey == secret)

    let refusals: [([String: String], String)] = [
      (
        ["MOUNTAYA_PUBLISHABLE_KEY": publishable],
        "MOUNTAYA_SECRET_KEY is not set: export it in this shell, from your organization's API "
          + "keys, then run mise run trail:session again."
      ),
      (
        ["MOUNTAYA_SECRET_KEY": secret, "MOUNTAYA_PUBLISHABLE_KEY": "  "],
        "MOUNTAYA_PUBLISHABLE_KEY is not set: export it in this shell, from your organization's "
          + "API keys, then run mise run trail:session again."
      ),
      (
        [:],
        "MOUNTAYA_PUBLISHABLE_KEY and MOUNTAYA_SECRET_KEY are not set: export them in this "
          + "shell, from your organization's API keys, then run mise run trail:session again."
      ),
    ]
    for (environment, sentence) in refusals {
      #expect(throws: SessionKeysMissing.self) { try SessionKeys.read(environment) }
      do {
        _ = try SessionKeys.read(environment)
      } catch {
        #expect(error.description == sentence)
        #expect(!error.description.contains(publishable))
        #expect(!error.description.contains(secret))
      }
    }
  }

  @Test("the keys print neither key")
  func keysPrintNoKey() {
    let keys = SessionKeys(publishableKey: publishable, secretKey: secret)
    var dumped = ""
    dump(keys, to: &dumped)

    for printed in [String(describing: keys), String(reflecting: keys), dumped] {
      #expect(!printed.contains(publishable), "\(printed)")
      #expect(!printed.contains(secret), "\(printed)")
    }
  }

  @Test("a request that is no HTTP/1.1 is a 400, and nothing is minted")
  func refusesWhatIsNoRequest() async throws {
    let exchange = Answered { _ in json(500, body: "{}") }

    try await Self.serve(exchange) { address in
      let host = try #require(address.host)
      let port = try #require(address.port)
      let answer = try await Self.raw("NOT HTTP\r\n\r\n", host: host, port: port)
      #expect(answer.hasPrefix("HTTP/1.1 400 Bad Request\r\n"), "\(answer)")
    }

    #expect(await exchange.requests.isEmpty)
  }

  /// raw writes `text` to the server as it is and reads its whole answer, as text.
  static func raw(_ text: String, host: String, port: Int) async throws -> String {
    let session = URLSession(configuration: .ephemeral)
    defer { session.invalidateAndCancel() }
    let stream = session.streamTask(withHostName: host, port: port)
    stream.resume()
    try await stream.write(Data(text.utf8), timeout: 5)
    var answer = Data()
    while true {
      let (read, atEnd) = try await stream.readData(ofMinLength: 1, maxLength: 4_096, timeout: 5)
      answer.append(read ?? Data())
      if atEnd { break }
    }
    return String(decoding: answer, as: UTF8.self)
  }
}
