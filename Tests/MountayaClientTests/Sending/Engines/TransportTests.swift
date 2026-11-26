import Foundation
import Simulation
import Synchronization
import Testing

@testable import MountayaClient

@Suite("Transport")
struct TransportTests {
  @Test("an answer folds its headers as it arrives, and reads each by its name in any letter case")
  func answer() {
    let answer = Transport.Answer(
      status: 200, headers: ["X-Request-Id": "req_1", "Vary": "a", "vary": "b"], body: Data())

    #expect(answer.headers == ["x-request-id": "req_1", "vary": "a, b"])
    #expect(answer.header("x-REQUEST-id") == "req_1")
    #expect(answer.header("VARY") == "a, b")
    #expect(answer.header("Location") == nil)
  }

  private static let unavailable =
    #"{"errors":[{"message":"busy","extensions":{"code":"SERVICE_UNAVAILABLE"}}]}"#
  private static let keyInUse =
    #"{"errors":[{"message":"running","extensions":{"code":"IDEMPOTENCY_KEY_IN_USE"}}]}"#

  /// send sends one envelope call of `facts` through a scripted transport.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static func send(
    _ transport: Transport,
    of facts: OperationFacts,
    headers: KeyValuePairs<String, String?> = [:],
    body: OperationBody = .none,
    key: String? = nil,
    ifMatch: String? = nil,
    options: RequestOptions = RequestOptions()
  ) async throws -> Response<JSONValue, [String: JSONValue]?> {
    try await transport.envelope(
      OperationRequest(
        facts: facts, headers: headers, body: body, idempotencyKey: key, ifMatch: ifMatch),
      options: options
    )
  }

  @Test("a write sends one key on every attempt, and the error it raises carries it")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func oneKeyPerCall() async throws {
    let (error, keys) = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [], exhausted: .answer(503, body: Self.unavailable))
      let transport = Transport.scripted(simulation, exchange: exchange, retry: try .quick())
      let error = await #expect(throws: MountayaError.self) {
        _ = try await Self.send(transport, of: .write())
      }
      return (error, await exchange.sent.map { $0.request.header("Idempotency-Key") })
    }

    #expect(keys == Array(repeating: "6f1c2a9e-3b4d-4e5f-8a6b-7c8d9e0f1a2b", count: 3))
    #expect(error?.name == "ServerError")
    #expect(error?.idempotencyKey == "6f1c2a9e-3b4d-4e5f-8a6b-7c8d9e0f1a2b")
  }

  @Test("a ceiling settles at once as a rate-limit failure naming no wait")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func ceiling() async throws {
    let ceiling =
      #"{"errors":[{"message":"Seats used up.","extensions":{"code":"LIMIT_REACHED"}}],"#
      + #""extensions":{"metadata":{"limit":"seats","allowed":5,"used":5}}}"#
    let (error, sent) = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [], exhausted: .answer(429, body: ceiling))
      let transport = Transport.scripted(simulation, exchange: exchange, retry: try .quick())
      let error = await #expect(throws: MountayaError.self) {
        _ = try await Self.send(transport, of: .write(), key: "seat-9c1d")
      }
      return (error, await exchange.sent.count)
    }

    #expect(sent == 1)
    #expect(error?.idempotencyKey == "seat-9c1d")
    guard case .api(let apiError)? = error else {
      Issue.record("the failure is not one the API answered")
      return
    }
    #expect(apiError.kind == .rateLimit)
    #expect(apiError.code == "LIMIT_REACHED")
    #expect(apiError.retryAfter == nil)
    #expect(
      apiError.metadata
        == .object(["limit": .string("seats"), "allowed": .number(5), "used": .number(5)]))
  }

  @Test("a key in use is asked again a second apart at least, counted against no ceiling")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func keyInUse() async throws {
    let sent = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [
          .answer(409, headers: ["Retry-After": "0"], body: Self.keyInUse),
          .answer(409, body: Self.keyInUse),
          .answer(201, body: #"{"data":null}"#),
        ])
      let transport = Transport.scripted(
        simulation, exchange: exchange, retry: try .quick(maxRetries: 0))
      let response = try await Self.send(transport, of: .write(), key: "order-7f3a")
      #expect(response.status == 201)
      return await exchange.sent
    }

    #expect(sent.map(\.at) == [.zero, .seconds(1), .seconds(2)])
    #expect(sent.allSatisfy { $0.request.header("Idempotency-Key") == "order-7f3a" })
  }

  @Test("the hook is told of every attempt an answer came back to, its replay and its request id")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func reports() async throws {
    let reports = try await Simulation.run { simulation in
      let told = Mutex<[ResponseReport]>([])
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [
          .drop(),
          .answer(503, headers: ["X-Request-Id": "a1"], body: Self.unavailable),
          .answer(
            200, headers: ["Idempotent-Replayed": "true", "x-request-id": "b2"],
            body: #"{"data":null}"#),
        ])
      let transport = Transport.scripted(
        simulation, exchange: exchange, retry: try .quick(),
        onResponse: { report in told.withLock { $0.append(report) } })
      _ = try await Self.send(transport, of: .write())
      return told.withLock { $0 }
    }

    #expect(reports.map(\.attempt) == [1, 2])
    #expect(reports.map(\.status) == [503, 200])
    #expect(reports.map(\.requestId) == ["a1", "b2"])
    #expect(reports.map(\.isReplayed) == [false, true])
    #expect(reports.allSatisfy { $0.operationId == "writeThing" && $0.surface == .rest })
  }

  @Test(
    "a header the client writes, a stream's Accept and a budget of nothing are refused before any request"
  )
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func refusals() async throws {
    let sent = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(clock: simulation.clock, replies: [])
      let transport = Transport.scripted(simulation, exchange: exchange)
      await #expect(throws: MountayaError.self) {
        _ = try await Self.send(transport, of: .write(), headers: ["idempotency-key": "mine"])
      }
      await #expect(throws: MountayaError.self) {
        _ = try await Self.send(
          transport, of: .write(), headers: ["x-mountaya-client": "mountaya-swift/9.9.9"])
      }
      await #expect(throws: MountayaError.self) {
        _ = try await Self.send(transport, of: .write(), headers: ["Accept": "text/event-stream"])
      }
      await #expect(throws: MountayaError.self) {
        _ = try await Self.send(transport, of: .write(), options: RequestOptions(timeout: .zero))
      }
      await #expect(throws: MountayaError.self) {
        _ = try await Self.send(transport, of: .write(conditional: true), ifMatch: "\"d4\n2\"")
      }
      return await exchange.sent.count
    }

    #expect(sent == 0)
  }

  /// RFC 9110 writes a field name as a token, so a name holding a space, a colon or a bracket is
  /// no header: a loader refuses it, or writes `X-Trace: a` as a header of its own.
  @Test("a header's name that is no RFC 9110 token is refused before any request")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func headerNameTokens() async throws {
    let (refused, sent) = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [], exhausted: .answer(200, body: #"{"data":null}"#))
      let transport = Transport.scripted(simulation, exchange: exchange)
      var refused: [String] = []
      for name in ["X-API-Key: x", "X Trace", "X(Trace)", "X@Trace", "X\"Trace", "X/Trace", "{X}"] {
        do {
          _ = try await Self.send(
            transport, of: .write(method: "GET", key: false), headers: [name: "t"])
        } catch MountayaError.configuration {
          refused.append(name)
        }
      }
      _ = try await Self.send(
        transport, of: .write(method: "GET", key: false),
        headers: ["X-Trace_1.a!#$%&'*+^`|~": "t"])
      return (refused, await exchange.sent)
    }

    #expect(refused.count == 7, "\(refused)")
    #expect(sent.count == 1, "a token of every character a field name takes is sent")
    #expect(sent.first?.request.header("X-Trace_1.a!#$%&'*+^`|~") == "t")
  }

  /// A `Retry-After` date is waited out to the whole second after it, the wait the error carries,
  /// so the transport never asks again before the instant the server named.
  @Test("a Retry-After date is waited out rounded up to the whole second, as the error carries it")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func retryAfterDateRoundsUp() async throws {
    let busy = #"{"errors":[{"message":"slow down","extensions":{"code":"RATE_LIMITED"}}]}"#
    let sent = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [
          // Answered 0.8 s after the epoch, naming the instant 2 s after it: 1.2 s ahead.
          .answer(
            429, headers: ["Retry-After": "Thu, 01 Jan 1970 00:00:02 GMT"], body: busy,
            after: .milliseconds(800)),
          .answer(200, body: #"{"data":null}"#),
        ])
      let transport = Transport.scripted(simulation, exchange: exchange, retry: try .quick())
      _ = try await Self.send(transport, of: .write(method: "GET", idempotent: true, key: false))
      return await exchange.sent.map(\.at)
    }

    #expect(sent == [.zero, .milliseconds(2_800)], "the 1.2 s waited as 2 s")
  }

  @Test("every attempt names the SDK beside the caller's own headers, a repeated one's included")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func identification() async throws {
    let sent = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [.answer(503, body: Self.unavailable), .answer(200, body: #"{"data":null}"#)])
      let transport = Transport.scripted(simulation, exchange: exchange, retry: try .quick())
      _ = try await Self.send(
        transport, of: .write(method: "GET", idempotent: true, key: false),
        headers: ["X-Trace": "t1"])
      return await exchange.sent.map(\.request)
    }

    #expect(sent.count == 2)
    #expect(sent.allSatisfy { $0.header("X-Mountaya-Client") == ClientIdentification.value })
    #expect(sent.allSatisfy { $0.header("X-Trace") == "t1" })
  }

  /// A dictionary keeps `content-type` and `Content-Type` apart, and a platform that reads names
  /// without regard to case sends whichever it meets last, which differs from one process to the
  /// next: one name is one header, the body's type standing over the caller's.
  @Test(
    "a header the caller writes in another case replaces the one held, the body's type standing")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func headersReplacedWithoutRegardToCase() async throws {
    let sent = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [], exhausted: .answer(200, body: #"{"data":null}"#))
      let transport = Transport.scripted(simulation, exchange: exchange)
      _ = try await Self.send(
        transport, of: .write(key: false),
        headers: ["content-type": "text/plain", "X-Trace": "t1", "x-trace": "t2"],
        body: .json(["name": "Refuge"]))
      _ = try await Self.send(
        transport, of: .write(method: "GET", key: false), headers: ["content-type": "text/plain"])
      return await exchange.sent.map(\.request)
    }

    let named = { (request: ExchangeRequest, name: String) in
      request.headers.keys.filter { $0.lowercased() == name }
    }
    #expect(named(sent[0], "content-type").count == 1)
    #expect(sent[0].header("Content-Type") == "application/json")
    #expect(named(sent[0], "x-trace").count == 1)
    #expect(sent[0].header("X-Trace") == "t2", "the caller's last spelling of a name stands")
    #expect(sent[1].header("Content-Type") == "text/plain", "with no body, the caller's own")
  }

  @Test(
    "the language rides every request, and a visitor's cookies only under a share token that asks")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func languageAndCookies() async throws {
    let sent = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [], exhausted: .answer(200, body: #"{"data":null}"#))
      let read = OperationFacts.write(method: "GET", key: false)
      let publishable = Transport.scripted(
        simulation, exchange: exchange, language: "fr-CH, fr;q=0.9")
      let visitor = Transport.scripted(
        simulation, exchange: exchange,
        credential: .share(token: "share_abc", cookies: { url in "visit=\(url.path)" }))
      _ = try await Self.send(publishable, of: read)
      _ = try await Self.send(visitor, of: read)
      return await exchange.sent.map(\.request)
    }

    #expect(sent[0].header("Accept-Language") == "fr-CH, fr;q=0.9")
    #expect(sent[0].header("Cookie") == nil)
    #expect(sent[1].header("Cookie") == "visit=/v1/things")
    #expect(sent[1].header("X-Share-Token") == nil)
  }

  @Test("a request waits for a first session token its source reports on its way")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func firstToken() async throws {
    let sent = try await Simulation.run { simulation in
      let source = MovingSource(SessionSnapshot(isMinting: true))
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [.answer(200, body: #"{"data":null}"#)])
      let transport = Transport.scripted(
        simulation, exchange: exchange,
        credential: .publishable(key: "pk_test_abc", sessionToken: .source(source)))
      try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { _ = try await Self.send(transport, of: .write(method: "GET", key: false)) }
        group.addTask {
          try await simulation.clock.sleep(for: .milliseconds(100))
          source.move(to: SessionSnapshot(token: "sess_minted"))
        }
        try await group.waitForAll()
      }
      return await exchange.sent
    }

    #expect(sent.map(\.at) == [.milliseconds(100)])
    #expect(sent.first?.request.header("X-Session-Token") == "sess_minted")
  }

  /// The wait for a first token and the attempt's budget race in one group: a cancellation must
  /// end both alike, never a request read as going out with no token, which the projection refuses
  /// with a `ConfigurationError`.
  @Test("a call cancelled while its first session token is on its way throws its cancellation")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func cancelledWhileTheFirstTokenIsOnItsWay() async throws {
    let (thrown, sent) = try await Simulation.run { simulation in
      let source = MovingSource(SessionSnapshot(isMinting: true))
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [.answer(200, body: #"{"data":null}"#)])
      let transport = Transport.scripted(
        simulation, exchange: exchange,
        credential: .publishable(key: "pk_test_abc", sessionToken: .source(source)))
      let facts = OperationFacts.write(
        method: "GET", key: false, credentials: CredentialDeclaration(requiresSession: true))
      var thrown: (any Error)?
      await withTaskGroup(of: (any Error)?.self) { group in
        group.addTask {
          do {
            _ = try await Self.send(transport, of: facts)
            return nil
          } catch {
            return error
          }
        }
        try? await simulation.clock.sleep(for: .milliseconds(100))
        group.cancelAll()
        thrown = await group.next() ?? nil
      }
      return (thrown, await exchange.sent)
    }

    #expect(thrown is CancellationError, "\(String(describing: thrown))")
    #expect(sent.isEmpty)
  }

  @Test("a Data API call sends its digest alone first, and its document where the server asks")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func persistedQueries() async throws {
    let (bodies, result) = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [
          .answer(200, body: #"{"errors":[{"message":"PersistedQueryNotFound"}]}"#),
          .answer(200, body: #"{"data":{"directions":{"routes":[]}}}"#),
        ])
      let transport = Transport.scripted(
        simulation, exchange: exchange,
        credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc"))
      let result: DataSchema.DirectionsResult = try await transport.query(
        .directions, facts: .directions,
        input: DataSchema.DirectionsInput(activity: "hiking", waypoints: [[6.86, 45.83]]),
        select: nil, options: RequestOptions())
      let bodies = try await exchange.sent.map { sent in
        try JSONDecoder().decode(JSONValue.self, from: sent.request.body ?? Data())
      }
      return (bodies, result)
    }

    #expect(result.routes?.isEmpty == true)
    guard case .object(let first) = bodies.first, case .object(let second) = bodies.last else {
      Issue.record("the Data API's requests are no JSON objects")
      return
    }
    #expect(first["query"] == nil)
    #expect(first["extensions"] != nil)
    #expect(second["query"] != nil)
    #expect(second["extensions"] != nil)
  }

  /// directions sends `calls` Data API calls through one transport whose exchange answers
  /// `replies`, and returns the body each request sent, read as JSON, and what each call ended with.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static func directions(_ replies: [ScriptedExchange.Reply], calls: Int) async throws
    -> (bodies: [[String: JSONValue]], outcomes: [Result<DataSchema.DirectionsResult, any Error>])
  {
    try await Simulation.run { simulation in
      let exchange = ScriptedExchange(clock: simulation.clock, replies: replies)
      let transport = Transport.scripted(
        simulation, exchange: exchange,
        credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc"))
      var outcomes: [Result<DataSchema.DirectionsResult, any Error>] = []
      for _ in 0..<calls {
        do {
          let result: DataSchema.DirectionsResult = try await transport.query(
            .directions, facts: .directions,
            input: DataSchema.DirectionsInput(activity: "hiking", waypoints: [[6.86, 45.83]]),
            select: nil, options: RequestOptions())
          outcomes.append(.success(result))
        } catch {
          outcomes.append(.failure(error))
        }
      }
      let bodies = try await exchange.sent.map { sent in
        guard
          case .object(let members) = try JSONDecoder().decode(
            JSONValue.self, from: sent.request.body ?? Data())
        else { return [String: JSONValue]() }
        return members
      }
      return (bodies, outcomes)
    }
  }

  /// The Data API with the extension turned off finds no operation in a body that carries no
  /// document, and says so before any field runs, under a failing status rather than a 200.
  @Test(
    "a digest declined under 422 is answered with the document, and every later call sends it alone"
  )
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func persistedQueriesDeclinedUnderFailingStatus() async throws {
    let declined =
      #"{"errors":[{"message":"no operation provided","#
      + #""extensions":{"code":"GRAPHQL_VALIDATION_FAILED"}}]}"#
    let routes = #"{"data":{"directions":{"routes":[]}}}"#
    let (bodies, outcomes) = try await Self.directions(
      [.answer(422, body: declined), .answer(200, body: routes), .answer(200, body: routes)],
      calls: 2)

    #expect(outcomes.count == 2)
    for outcome in outcomes {
      #expect((try? outcome.get())?.routes?.isEmpty == true, "the call is answered its result")
    }
    try #require(bodies.count == 3)
    #expect(bodies[0]["query"] == nil, "the first attempt sends its digest alone")
    #expect(bodies[0]["extensions"] != nil)
    #expect(bodies[1]["query"] != nil, "the refusal is answered with the document")
    #expect(bodies[1]["extensions"] == nil, "a declined protocol sends no digest")
    #expect(bodies[2]["query"] != nil, "the next call sends its document from the start")
    #expect(bodies[2]["extensions"] == nil, "the protocol stays declined for the transport")
  }

  @Test("a failing answer whose errors refuse no digest fails the call, and nothing is sent again")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func failingAnswerRefusingNothing() async throws {
    let invalid =
      #"{"errors":[{"message":"Cannot query field \"walk\".","#
      + #""extensions":{"code":"GRAPHQL_VALIDATION_FAILED"}}]}"#
    let (bodies, outcomes) = try await Self.directions([.answer(422, body: invalid)], calls: 1)

    #expect(bodies.count == 1)
    guard case .failure(let error as MountayaError)? = outcomes.first,
      case .api(let apiError) = error
    else {
      Issue.record("the failure is not one the API answered")
      return
    }
    #expect(apiError.status == 422)
    #expect(apiError.code == "GRAPHQL_VALIDATION_FAILED")
  }

  @Test("a success whose body does not decode is the base APIError, the decoder's error beneath it")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func undecodable() async throws {
    let error = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock, replies: [.answer(200, body: "not json")])
      let transport = Transport.scripted(simulation, exchange: exchange)
      return await #expect(throws: MountayaError.self) {
        _ = try await Self.send(transport, of: .write(method: "GET", key: false))
      }
    }

    guard case .api(let apiError)? = error else {
      Issue.record("the failure is not one the API answered")
      return
    }
    #expect(apiError.kind == .other)
    #expect(apiError.status == 200)
    #expect(apiError.cause is DecodingError)
  }

  @Test(
    "a format: uri value with no scheme is read as the answer wrote it, and refused in a body before any request"
  )
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func schemelessUrl() async throws {
    let (answered, written, sent) = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [
          .answer(
            200,
            body:
              #"{"data":{"id":"55763749-32b4-42d5-9f62-b6c51ef54d99","tile_size":512,"url":"/v1/elevation.json"}}"#
          )
        ])
      let transport = Transport.scripted(simulation, exchange: exchange)
      let written = await #expect(throws: MountayaError.self) {
        let body = RestSchema.WaypointLink(label: "Topo", url: URI("refuge.example/topo"))
        _ = try await Self.send(transport, of: .write(key: false), body: .json(body))
      }
      let sentBefore = await exchange.sent.count
      let answered: Response<TileSchema.Elevation, [String: JSONValue]?> =
        try await transport.envelope(
          OperationRequest(facts: .write(method: "GET", key: false)), options: RequestOptions())
      return (answered, written, sentBefore)
    }

    #expect(sent == 0)
    guard case .configuration(let refusal)? = written else {
      Issue.record("the body is not refused as the client's configuration")
      return
    }
    #expect(refusal.cause is EncodingError)
    #expect(answered.data.url.text == "/v1/elevation.json")
    // An answer a caller keeps writes back as it arrived, its address with no scheme included.
    #expect(try ScriptedSender.json(answered.data.url) == #""/v1/elevation.json""#)
  }

  @Test("a cancellation the exchange throws ends the call as it is, and is never repeated")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func exchangeCancellation() async throws {
    let sent = try await Simulation.run { simulation in
      var sent: [Int] = []
      for facts in [OperationFacts.write(method: "GET", idempotent: true, key: false), .write()] {
        let exchange = ScriptedExchange(
          clock: simulation.clock, replies: [.cancel(), .answer(200, body: #"{"data":{}}"#)])
        let transport = Transport.scripted(simulation, exchange: exchange)
        await #expect(throws: CancellationError.self) {
          _ = try await Self.send(transport, of: facts)
        }
        sent.append(await exchange.sent.count)
      }
      return sent
    }

    #expect(sent == [1, 1])
  }

  @Test("a file comes back with the content type the server chose")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func binary() async throws {
    let file = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [.answer(200, headers: ["Content-Type": "application/gpx+xml"], body: "<gpx/>")])
      let transport = Transport.scripted(simulation, exchange: exchange)
      return try await transport.binary(
        OperationRequest(facts: .write(method: "GET", key: false)), options: RequestOptions())
    }

    #expect(file == BinaryResponse(bytes: Data("<gpx/>".utf8), contentType: "application/gpx+xml"))
  }

  /// MovingSource is a session source a test moves from state to state.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private final class MovingSource: SessionTokenSource {
    private let state:
      Mutex<(snapshot: SessionSnapshot, readers: [AsyncStream<SessionSnapshot>.Continuation])>

    init(_ snapshot: SessionSnapshot) {
      state = Mutex((snapshot, []))
    }

    var snapshot: SessionSnapshot {
      state.withLock { $0.snapshot }
    }

    func subscribe() -> AsyncStream<SessionSnapshot> {
      AsyncStream { continuation in
        state.withLock { state in
          state.readers.append(continuation)
          continuation.yield(state.snapshot)
        }
      }
    }

    func move(to snapshot: SessionSnapshot) {
      state.withLock { state in
        state.snapshot = snapshot
        state.readers.forEach { $0.yield(snapshot) }
      }
    }
  }
}
