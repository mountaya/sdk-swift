import Foundation
import GateSupport
import MountayaClient
import Simulation

extension PublicRunners {
  /// timeoutBudget measures an attempt's budget as the time from sending an attempt nothing ever
  /// answers to the `ConnectionError` it settles as, on a simulation's clock.
  ///
  /// The operation is called by its declaration, carrying the case's own budget as its
  /// `timeoutMs`; the client is built with the case's budget, or with none where the case leaves
  /// it out, so the default is the client's own; and the call names its budget through
  /// `RequestOptions`. The operation is neither idempotent nor keyed, so nothing repeats it.
  ///
  /// A budget of zero or less is refused where it is given, as the client is built or as the call
  /// is made, before any request, and the answer is then the refusal's class.
  static let timeoutBudget = Runner(id: "transport.timeout.budget", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let server = try input.optionalNumber(at: "serverBudgetMs").map { Duration.milliseconds($0) }
    let client = try input.optionalNumber(at: "clientTimeoutMs").map { Duration.milliseconds($0) }
    let call = try input.optionalNumber(at: "callTimeoutMs").map { Duration.milliseconds($0) }
    return try await Simulation.run { simulation -> RunnerOutcome in
      let exchange = Scripted.Exchange(clock: simulation.clock, replies: [], exhausted: .never)
      do {
        let mountaya =
          try client.map {
            try Scripted.client(simulation, exchange: exchange, retry: noRetries, timeout: $0)
          } ?? Scripted.client(simulation, exchange: exchange, retry: noRetries)
        let _: Response<JSONValue, JSONValue?> = try await mountaya.send(
          OperationDeclaration(operationId: "writeThing", method: "POST", timeout: server),
          path: "/v1/things",
          options: RequestOptions(timeout: call)
        )
      } catch MountayaError.connection {
        return .value(.milliseconds(simulation.elapsed))
      } catch let refusal as MountayaError {
        guard case .configuration = refusal, await exchange.sent.isEmpty else { throw refusal }
        return .refused(refusal.name)
      }
      throw FixtureError(
        description: "the attempt settled as something other than a connection error")
    }
  }

  /// idempotencyKey makes the case's calls one after the other, each failing its first attempts
  /// as the case says before one is answered, and answers with the key every attempt sent, a key
  /// the client drew written as a label of its order.
  static let idempotencyKey = Runner(id: "transport.idempotency.key", table: .public) {
    fixture, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let pattern = try (fixture.constants ?? .object([])).string(at: "drawnKeyPattern")
    let drawn = try Regex(pattern)
    let input = fixtureCase.input
    let declaration = OperationDeclaration(
      operationId: "writeThing",
      method: try input.string(at: "method"),
      idempotent: try input.flag(at: "idempotent"),
      declaresIdempotencyKey: try input.flag(at: "declaresKey")
    )
    let given = try input.optionalString(at: "idempotencyKey")
    let calls = try input.integer(at: "calls")
    var failures: [Scripted.Reply] = []
    for failure in try input.array(at: "failures") {
      guard let status = try failure.optionalInteger(at: "status") else {
        failures.append(.drop())
        continue
      }
      var headers: [String: String] = [:]
      if let retryAfter = try failure.optionalString(at: "retryAfterHeader") {
        headers["Retry-After"] = retryAfter
      }
      failures.append(
        .answer(
          status: status, headers: headers,
          body: Scripted.errorBody(code: try failure.optionalString(at: "code")))
      )
    }
    let script = Array(
      repeating: failures + [.answer(status: 200, body: Scripted.emptySuccess)], count: calls
    )
    .flatMap { $0 }
    let keys = input["randomSource"]?.boolValue ?? true
    let (sent, refusal) = try await Simulation.run { simulation -> ([String?], String?) in
      let exchange = Scripted.Exchange(clock: simulation.clock, replies: script)
      let client = try Scripted.client(
        simulation, exchange: exchange, retry: twoQuickRetries, random: Scripted.Random(keys: keys))
      var refusal: String?
      for _ in 0..<calls {
        do {
          let _: Response<JSONValue, JSONValue?> = try await client.send(
            declaration, path: "/v1/things", idempotencyKey: given)
        } catch let error as MountayaError {
          if case .configuration = error {
            refusal = error.name
          }
        }
      }
      return (await exchange.sent.map { $0.request.header("Idempotency-Key") }, refusal)
    }
    var labels: [String: String] = [:]
    var written: [OrderedJSON] = []
    for key in sent {
      guard let key else {
        written.append(.null)
        continue
      }
      if key == given {
        written.append(.string(key))
        continue
      }
      guard key.wholeMatch(of: drawn) != nil else {
        throw FixtureError(description: "the drawn key `\(key)` is no version 4 UUID in lowercase")
      }
      let label = labels[key] ?? "k\(labels.count + 1)"
      labels[key] = label
      written.append(.string(label))
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "keys", value: .array(written)),
        OrderedJSON.Member(key: "refused", value: refusal.map(OrderedJSON.string) ?? .null),
      ])
    )
  }

  /// policy is the fixtures' retry policy with the case's wait budget, or the standard one's.
  static func policy(maxRetries: Int, waitBudget: Duration?) throws -> RetryPolicy {
    try RetryPolicy(
      maxRetries: maxRetries,
      baseDelay: .zero,
      maxDelay: .zero,
      waitBudget: waitBudget ?? RetryPolicy.standard.waitBudget
    )
  }

  /// idempotencyAnswerUnavailable sends a keyed write whose every attempt is answered with the
  /// case's 409, and answers with how many attempts the call made, the error it raised, and what
  /// that error carries of the answer the write was first given.
  static let idempotencyAnswerUnavailable = Runner(
    id: "transport.idempotency.answer-unavailable", table: .public
  ) { _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let code = try input.string(at: "code")
    var body: [OrderedJSON.Member] = [
      OrderedJSON.Member(
        key: "errors",
        value: .array([
          .object([
            OrderedJSON.Member(
              key: "extensions",
              value: .object([OrderedJSON.Member(key: "code", value: .string(code))])),
            OrderedJSON.Member(key: "message", value: .string("scripted")),
          ])
        ])
      )
    ]
    if let metadata = input["metadata"], !metadata.isNull {
      body.append(
        OrderedJSON.Member(
          key: "extensions", value: .object([OrderedJSON.Member(key: "metadata", value: metadata)]))
      )
    }
    var headers: [String: String] = [:]
    if let retryAfter = try input.optionalString(at: "retryAfterHeader") {
      headers["Retry-After"] = retryAfter
    }
    let reply = Scripted.Reply.answer(
      status: 409, headers: headers, body: Scripted.json(.object(body)))
    let policy = try policy(
      maxRetries: 2,
      waitBudget: try input.optionalNumber(at: "maxWaitMs").map { .milliseconds($0) }
    )
    let draw = try input.optionalNumber(at: "random") ?? 0
    let (error, attempts) = try await Simulation.run { simulation -> (MountayaError, Int) in
      let exchange = Scripted.Exchange(clock: simulation.clock, replies: [], exhausted: reply)
      let client = try Scripted.client(
        simulation, exchange: exchange, retry: policy, random: Scripted.Random(draw: draw))
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          OperationDeclaration(
            operationId: "postThing", method: "POST", declaresIdempotencyKey: true),
          path: "/v1/things"
        )
      } catch let error as MountayaError {
        return (error, await exchange.sent.count)
      }
      throw FixtureError(description: "the write raised nothing")
    }
    guard case .api(let apiError) = error else {
      throw FixtureError(description: "the write raised \(error.name)")
    }
    let answer = apiError.unavailableAnswer.map { answer in
      OrderedJSON.object([
        OrderedJSON.Member(key: "etag", value: answer.etag.map(OrderedJSON.string) ?? .null),
        OrderedJSON.Member(
          key: "location", value: answer.location.map(OrderedJSON.string) ?? .null),
        OrderedJSON.Member(
          key: "status", value: answer.status.map { .number(Double($0)) } ?? .null),
      ])
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "answer", value: answer ?? .null),
        OrderedJSON.Member(key: "attempts", value: .number(Double(attempts))),
        OrderedJSON.Member(key: "class", value: .string(error.name)),
        OrderedJSON.Member(key: "conflict", value: .bool(apiError.kind.isConflict)),
      ])
    )
  }

  /// idempotencyKeyInUse sends a write with the case's key whose first attempts are answered
  /// that the key is in use, and answers with how many attempts it made, the waits between them
  /// on the simulation's clock, and the error it raised with the key that error carries.
  static let idempotencyKeyInUse = Runner(id: "transport.idempotency.key-in-use", table: .public) {
    fixture, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let key = try (fixture.constants ?? .object([])).string(at: "idempotencyKey")
    let input = fixtureCase.input
    var headers: [String: String] = [:]
    if let retryAfter = try input.optionalString(at: "retryAfterHeader") {
      headers["Retry-After"] = retryAfter
    }
    let inUse = Scripted.Reply.answer(
      status: 409, headers: headers, body: Scripted.errorBody(code: "IDEMPOTENCY_KEY_IN_USE"))
    let created = Scripted.Reply.answer(status: 201, body: Scripted.emptySuccess)
    let replies: [Scripted.Reply]
    let exhausted: Scripted.Reply
    if let count = try input.optionalInteger(at: "inUse") {
      replies = Array(repeating: inUse, count: count) + [created]
      exhausted = .never
    } else {
      replies = []
      exhausted = inUse
    }
    let policy = try policy(
      maxRetries: try input.integer(at: "maxRetries"),
      waitBudget: .milliseconds(try input.number(at: "maxWaitMs"))
    )
    let draw = try input.number(at: "random")
    let (error, sent) = try await Simulation.run {
      simulation -> (MountayaError?, [Duration]) in
      let exchange = Scripted.Exchange(
        clock: simulation.clock, replies: replies, exhausted: exhausted)
      let client = try Scripted.client(
        simulation, exchange: exchange, retry: policy, random: Scripted.Random(draw: draw))
      var error: MountayaError?
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          OperationDeclaration(
            operationId: "postThing", method: "POST", declaresIdempotencyKey: true),
          path: "/v1/things",
          idempotencyKey: key
        )
      } catch let raised as MountayaError {
        error = raised
      }
      let sent = await exchange.sent
      guard sent.allSatisfy({ $0.request.header("Idempotency-Key") == key }) else {
        throw FixtureError(description: "an attempt sent another key")
      }
      return (error, sent.map(\.at))
    }
    let waits = zip(sent.dropFirst(), sent).map { $0 - $1 }
    return .value(
      .object([
        OrderedJSON.Member(key: "attempts", value: .number(Double(sent.count))),
        OrderedJSON.Member(key: "class", value: error.map { .string($0.name) } ?? .null),
        OrderedJSON.Member(
          key: "idempotencyKey", value: error?.idempotencyKey.map(OrderedJSON.string) ?? .null),
        OrderedJSON.Member(key: "waitsMs", value: .array(waits.map(OrderedJSON.milliseconds))),
      ])
    )
  }

  /// conditionalIfMatch sends the case's write with its tag, after a read of the same resource
  /// whose answer carries `seenEtag` where the case names one, and answers with the `If-Match`
  /// each attempt of the write sent and how it settled.
  static let conditionalIfMatch = Runner(id: "transport.conditional.if-match", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let codes = [404: "NOT_FOUND", 412: "PRECONDITION_FAILED", 503: "SERVICE_UNAVAILABLE"]
    var replies: [Scripted.Reply] = []
    let seen = try input.optionalString(at: "seenEtag")
    if let seen {
      let body = Data(#"{"data":{"etag":\#(OrderedJSON.string(seen).serialized())}}"#.utf8)
      replies.append(.answer(status: 200, headers: ["ETag": seen], body: body))
    }
    for answer in try input.array(at: "answers") {
      guard let status = answer.numberValue.flatMap({ Int(exactly: $0) }) else {
        throw FixtureError(description: "an answer is no status")
      }
      if (200...299).contains(status) {
        replies.append(.answer(status: status, body: Scripted.emptySuccess))
      } else {
        replies.append(
          .answer(status: status, body: Scripted.errorBody(code: codes[status] ?? "ERROR")))
      }
    }
    let declaration = OperationDeclaration(
      operationId: "changeThing",
      method: try input.string(at: "method"),
      declaresIdempotencyKey: true,
      isConditional: try input.flag(at: "declaresIfMatch")
    )
    let tag = try input.optionalString(at: "ifMatch")
    let script = replies
    let (outcome, tags) = try await Simulation.run { simulation -> (String, [String?]) in
      let exchange = Scripted.Exchange(clock: simulation.clock, replies: script)
      let client = try Scripted.client(simulation, exchange: exchange, retry: twoQuickRetries)
      if seen != nil {
        let _: Response<JSONValue, JSONValue?> = try await client.send(aRead, path: "/v1/things/th")
      }
      let read = await exchange.sent.count
      var outcome = "answered"
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          declaration, path: "/v1/things/th", ifMatch: tag)
      } catch let error as MountayaError {
        outcome = error.name
      }
      return (outcome, await exchange.sent.dropFirst(read).map { $0.request.header("If-Match") })
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "attempts", value: .number(Double(tags.count))),
        OrderedJSON.Member(
          key: "ifMatch", value: .array(tags.map { $0.map(OrderedJSON.string) ?? .null })),
        OrderedJSON.Member(key: "outcome", value: .string(outcome)),
      ])
    )
  }
}
