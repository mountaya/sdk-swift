import Foundation
import GateSupport
import Simulation

@testable import MountayaClient

extension InternalRunners {
  /// transport is a transport on a simulation's clock and wall clock, sending through
  /// `exchange` and drawing `draw` before every wait.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func transport(
    _ simulation: Simulation,
    exchange: any HTTPExchange,
    credential: Credential,
    timeout: Duration = AttemptBudget.clientDefault,
    draw: Double = 0
  ) -> Transport {
    Transport(
      configuration: Transport.Configuration(
        credential: credential,
        language: nil,
        baseUrls: .standard,
        retry: .standard,
        timeout: timeout,
        onResponse: nil
      ),
      exchange: exchange,
      sleeper: ClockSleeper(clock: simulation.clock),
      wallClock: Scripted.Wall(clock: simulation.clock),
      random: Scripted.Random(draw: draw)
    )
  }

  /// frameData is the `data:` of a frame of each event the stream fixtures name, as the API
  /// writes it.
  static let frameData: [String: String] = [
    "message-delta": #"{"text":"The"}"#,
    "message": #"{"content":"The second day is the long one.","message_index":0}"#,
    "reconnect": #"{"reason":"credential-expired"}"#,
    "presence.snapshot": #"{"members":[]}"#,
    "lock.snapshot": #"{"locks":[]}"#,
    "segment.changed":
      #"{"action":"updated","actor_id":"2b8d4f19-6a05-4e73-8c1f-9d3b7e05a24c","id":"c1f0a3d2-5b7e-4a86-9f21-3e4d5c6b7a80","itinerary_id":"8f14e45f-ceea-467a-9575-3f1b1a2d9c47","kind":"segment","occurred_at":"2026-05-12T09:14:07Z","organization_id":"0d9c2b7a-1e4f-4c3b-8a6d-5f7e9b1c2d3e","revision":4}"#,
  ]

  /// refusals is the status and the code of each open the stream fixtures name as refused.
  static let refusals: [String: (status: Int, code: String)] = [
    "unauthorized": (401, "UNAUTHORIZED"),
    "rate-limited": (429, "TOO_MANY_REQUESTS"),
    "unavailable": (503, "SERVICE_UNAVAILABLE"),
  ]

  /// joinData is the `data:` of a `presence.join` of the member `userId`, as the API writes it, on
  /// the one line a record's `data:` takes.
  static func joinData(_ userId: String) throws -> String {
    let member = String(decoding: try JSONEncoder().encode(userId), as: UTF8.self)
    return #"{"user_id":"# + member + #","connected_at":"2026-05-12T09:14:07Z"}"#
  }

  /// record writes one frame of the stream fixtures as the bytes of a record: the `data:` the
  /// frame states where it states one, as a record of an event no reader knows does, and else the
  /// one the API writes for its event.
  static func record(_ frame: OrderedJSON) throws -> String {
    let event = try frame.string(at: "event")
    let data: String
    if let stated = frame["data"] {
      let read = try JSONDecoder().decode(JSONValue.self, from: Data(stated.serialized().utf8))
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
      data = String(decoding: try encoder.encode(read), as: UTF8.self)
    } else if event == "presence.join" {
      data = try joinData(try frame.string(at: "userId"))
    } else if let written = frameData[event] {
      data = written
    } else {
      throw FixtureError(description: "no frame's data is written for the event `\(event)`")
    }
    return PublicRunners.sse(event: event, id: try frame.optionalString(at: "id"), data: data)
  }

  /// heartbeat is the comment the API writes on an open stream every 15 seconds.
  static let heartbeat = Data(": heartbeat\n\n".utf8)

  /// opening returns the request that opens the case's stream.
  static func opening(_ stream: String) throws -> OperationRequest {
    switch stream {
    case "agent":
      return OperationRequest(facts: .getAgentRunEvents, pathParameters: ["run_id": "ru"])
    case "collaboration":
      return OperationRequest(facts: .getItineraryEvents, pathParameters: ["itinerary_id": "it"])
    default:
      throw FixtureError(description: "no stream is called `\(stream)`")
    }
  }

  /// eventsReconnect reads a printed stream as a caller does, each open doing what the case's
  /// word for it says, on a simulation's clock and wall clock, and answers with the wait before
  /// each reopen, the position each reopen sent, and whether and with what the reader stopped.
  ///
  /// An open that stays open does so with the comment the API writes every 15 seconds, as the
  /// API does. The case ends where the reader opens the stream once more than the case scripts,
  /// or where it stops on its own. A case whose reader reads the stream as a user is read twice,
  /// once with a session token that names that user and once with one that names none and the
  /// stream told the user as it opens, and the two must answer alike; once alone where the client
  /// is told the token's expiry, since a session minted without `user_id` cannot read an editor stream,
  /// whose every open acts as a member. A case that states no user is read with the user every
  /// runner's minted session names where the client is told the expiry, and with a plain token
  /// otherwise. A case that names the user its session token names, `tokenUserId`, and the one the
  /// stream is told as it opens, `toldUserId`, is read with both, a source reporting the first and
  /// the stream told the second.
  static let eventsReconnect = Runner(id: "transport.events.reconnect", table: .internal) {
    fixture, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let stream = try input.string(at: "stream")
    let request = try opening(stream)
    let schedule = fixture.document["schedules"]?[stream] ?? .null
    try fixture.holdConstants(["retryAfterJitterMs": Backoff.retryAfterJitter / .milliseconds(1)])
    let rules =
      stream == "agent"
      ? RestSchema.AgentRunEvent.rules(for: request.facts.operationId)
      : RestSchema.CollabStreamEvent.rules(for: request.facts.operationId)
    guard
      try OrderedJSON.milliseconds(rules.baseWait) == .number(schedule.number(at: "baseMs")),
      try OrderedJSON.milliseconds(rules.maxWait) == .number(schedule.number(at: "maxMs")),
      try schedule.optionalInteger(at: "maxReopens") == rules.maxReopens,
      try rules.maxUnavailable.map(OrderedJSON.milliseconds)
        == schedule.optionalNumber(at: "maxUnavailableMs").map(OrderedJSON.number)
    else {
      throw FixtureError(description: "the fixture's schedule is not the stream's")
    }
    let table = fixture.document["opens"]?[stream] ?? .null
    var replies: [Scripted.Reply] = []
    for word in try input.array(at: "opens") {
      guard let name = word.stringValue, let open = table[name] else {
        throw FixtureError(description: "no open of the \(stream) stream is called \(word)")
      }
      let then = try open.string(at: "then")
      if let refusal = refusals[then] {
        let retryAfter = try open.optionalString(at: "retryAfterHeader")
        replies.append(
          .answer(
            status: refusal.status,
            headers: retryAfter.map { ["Retry-After": $0] } ?? [:],
            body: Scripted.errorBody(code: refusal.code)
          ))
        continue
      }
      let text = try open.array(at: "frames").map(record).joined()
      var chunks: [(at: Duration, bytes: Data)] = text.isEmpty ? [] : [(.zero, Data(text.utf8))]
      let lasts = Duration.milliseconds(try open.optionalNumber(at: "forMs") ?? 0)
      var beat = Duration.seconds(15)
      while beat < lasts {
        chunks.append((beat, heartbeat))
        beat += .seconds(15)
      }
      switch then {
      case "drops":
        replies.append(.stream(status: 200, body: .init(chunks: chunks, end: .drops(at: lasts))))
      case "closes":
        replies.append(.stream(status: 200, body: .init(chunks: chunks, end: .closes(at: lasts))))
      default: throw FixtureError(description: "no open ends as `\(then)`")
      }
    }
    let user = try input.optionalString(at: "userId")
    let namesNoUser = input["userId"]?.isNull == true
    if user != nil, stream == "agent" {
      throw FixtureError(description: "an agent run's stream is read as no user")
    }
    let expiresAt = try input.optionalNumber(at: "tokenExpiresAtMs")
    if namesNoUser, expiresAt != nil {
      throw FixtureError(description: "a session the client is told the expiry of names its user")
    }
    let draw = try input.number(at: "random")
    let script = replies

    /// read reads the stream with `sessionToken`, the stream told `member` as it opens where one
    /// is given.
    func read(_ sessionToken: SessionToken, member: String?) async throws -> OrderedJSON {
      let credential = Credential.publishable(key: "pk_test_abc", sessionToken: sessionToken)
      let (stopped, report, sent, activity) = try await Simulation.run {
        simulation -> (Bool, String?, [Scripted.Exchange.Sent], [Duration?]) in
        let (exhaustion, signal) = AsyncStream<Void>.makeStream()
        let exchange = Scripted.Exchange(
          clock: simulation.clock, replies: script, exhausted: .never,
          onExhausted: { signal.yield() }
        )
        let transport = transport(
          simulation, exchange: exchange, credential: credential, draw: draw)
        let (stopped, report) = await withTaskGroup(of: (Bool, String?)?.self) { group in
          group.addTask {
            do {
              switch stream {
              case "agent":
                let events: EventStream<RestSchema.AgentRunEvent> = try transport.events(
                  request, options: RequestOptions())
                for try await _ in events {}
              default:
                let events: EventStream<RestSchema.CollabStreamEvent> = try transport.events(
                  request, options: RequestOptions())
                for try await _ in member.map(events.reading(asUser:)) ?? events {}
              }
              return (true, nil)
            } catch is CancellationError {
              return nil
            } catch let error as MountayaError {
              return (true, error.name)
            } catch {
              return (true, "\(error)")
            }
          }
          group.addTask {
            for await _ in exhaustion {
              return (false, nil)
            }
            return nil
          }
          defer { group.cancelAll() }
          while let next = await group.next() {
            if let settled = next {
              return settled
            }
          }
          return (false, nil)
        }
        signal.finish()
        let sent = await exchange.sent
        var activity: [Duration?] = []
        for attempt in sent.indices {
          activity.append(await exchange.lastActivity(of: attempt))
        }
        return (stopped, report, sent, activity)
      }
      var waits: [OrderedJSON] = []
      for index in sent.indices.dropFirst() {
        guard let ended = activity[index - 1] else {
          throw FixtureError(description: "open \(index - 1) never ended and was opened again")
        }
        waits.append(.milliseconds(sent[index].at - ended))
      }
      return .object([
        OrderedJSON.Member(
          key: "reports", value: stopped ? report.map(OrderedJSON.string) ?? .null : .null),
        OrderedJSON.Member(
          key: "resumedFrom",
          value: .array(
            sent.dropFirst().map {
              $0.request.header("Last-Event-ID").map(OrderedJSON.string) ?? .null
            })
        ),
        OrderedJSON.Member(key: "stopped", value: .bool(stopped)),
        OrderedJSON.Member(key: "waitsMs", value: .array(waits)),
      ])
    }

    let tokenUser = try input.optionalString(at: "tokenUserId")
    let toldUser = try input.optionalString(at: "toldUserId")
    if tokenUser != nil || toldUser != nil {
      guard stream == "collaboration", input["userId"] == nil, expiresAt == nil else {
        throw FixtureError(
          description: "a token's user and a told one are read on a collaboration feed alone")
      }
      let source = PublicRunners.ScriptedSource(
        SessionSnapshot(token: "sess_abc", userId: tokenUser))
      return .value(try await read(.source(source), member: toldUser))
    }
    if let expiresAt {
      let session = RestSchema.Session(
        expires_at: Date(timeIntervalSince1970: expiresAt / 1000),
        user_id: user ?? "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1",
        token: "sess_abc"
      )
      return .value(try await read(.minted(session), member: nil))
    }
    guard let user else {
      return .value(try await read("sess_abc", member: nil))
    }
    let named = try await read(
      .source(PublicRunners.ScriptedSource(SessionSnapshot(token: "sess_abc", userId: user))),
      member: nil)
    let told = try await read("sess_abc", member: user)
    guard named == told else {
      throw FixtureError(
        description:
          "read as the user its session token names, the stream answers \(named.serialized()), "
          + "and told the user as it opens, \(told.serialized())")
    }
    return .value(named)
  }

  /// eventsStall opens a printed stream through the reader on a simulation's clock, the open
  /// answered and its stream delivering as the case says, and answers with how the reader gave
  /// the first open up and when, as its observer is told, or `open` where it still holds it when
  /// the case stops watching.
  static let eventsStall = Runner(id: "transport.events.stall", table: .internal) {
    fixture, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let constants = fixture.constants ?? .object([])
    guard
      try OrderedJSON.milliseconds(EventStreamRules.stallWindow)
        == .number(constants.number(at: "stallWindowMs")),
      try OrderedJSON.milliseconds(AttemptBudget.clientDefault)
        == .number((fixture.defaults ?? .object([])).number(at: "timeoutMs"))
    else {
      throw FixtureError(description: "the fixture's window or default budget is not the reader's")
    }
    let input = fixtureCase.input
    let stream = try input.string(at: "stream")
    let request = try opening(stream)
    let timeout = try input.optionalNumber(at: "timeoutMs").map { Duration.milliseconds($0) }
    let reply: Scripted.Reply
    if let answersAfter = try input.optionalNumber(at: "answersAfterMs").map({
      Duration.milliseconds($0)
    }) {
      let event =
        stream == "agent"
        ? #"{"event":"message-delta"}"# : #"{"event":"segment.changed","id":"1-0"}"#
      var chunks: [(at: Duration, bytes: Data)] = []
      for delivery in try input.array(at: "deliveries") {
        let at = Duration.milliseconds(try delivery.number(at: "atMs")) - answersAfter
        switch try delivery.string(at: "what") {
        case "comment": chunks.append((at, heartbeat))
        case "event": chunks.append((at, Data(try record(OrderedJSON.parse(event)).utf8)))
        case let other: throw FixtureError(description: "no delivery is called `\(other)`")
        }
      }
      reply = .stream(
        status: 200, body: .init(chunks: chunks, end: .staysOpen), after: answersAfter)
    } else {
      reply = .never
    }
    let observedFor = try input.optionalNumber(at: "observedForMs").map {
      Duration.milliseconds($0)
    }

    let (outcome, elapsed) = try await Simulation.run { simulation -> (String, Duration?) in
      let exchange = Scripted.Exchange(clock: simulation.clock, replies: [reply], exhausted: .never)
      let transport = transport(
        simulation, exchange: exchange,
        credential: .publishable(key: "pk_test_abc", sessionToken: "sess_abc"),
        timeout: timeout ?? AttemptBudget.clientDefault)
      let call = try transport.prepare(
        request, accept: StreamRefusal.mediaType, options: RequestOptions())
      let (ended, signal) = AsyncStream<(String, Duration)>.makeStream()
      let observer: @Sendable (MountayaError?) -> Void = { failure in
        signal.yield((failure?.name ?? "closed", simulation.elapsed))
      }
      return await withTaskGroup(of: (String, Duration?)?.self) { group in
        group.addTask {
          switch stream {
          case "agent":
            let reading = EventStreamReader<RestSchema.AgentRunEvent>(
              transport: transport, call: call, observer: observer
            ).makeIterator()
            while (try? await reading.next()) != nil {}
          default:
            let reading = EventStreamReader<RestSchema.CollabStreamEvent>(
              transport: transport, call: call, observer: observer
            ).makeIterator()
            while (try? await reading.next()) != nil {}
          }
          return nil
        }
        group.addTask {
          for await (name, at) in ended {
            return (name, at)
          }
          return nil
        }
        if let observedFor {
          group.addTask {
            try? await simulation.clock.sleep(for: observedFor)
            return ("open", nil)
          }
        }
        defer { group.cancelAll() }
        while let next = await group.next() {
          if let settled = next {
            signal.finish()
            return settled
          }
        }
        return ("unsettled", nil)
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "elapsedMs", value: elapsed.map(OrderedJSON.milliseconds) ?? .null),
        OrderedJSON.Member(key: "outcome", value: .string(outcome)),
      ])
    )
  }
}
