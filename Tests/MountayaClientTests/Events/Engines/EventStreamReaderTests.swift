import Foundation
import Simulation
import Testing

@testable import MountayaClient

@Suite("EventStreamReader")
struct EventStreamReaderTests {
  private static let session = Credential.publishable(key: "pk_test_abc", sessionToken: "sess_abc")

  private static func record(event: String, data: String, id: String? = nil) -> String {
    (id.map { "id: \($0)\n" } ?? "") + "event: \(event)\ndata: \(data)\n\n"
  }

  private static let message = #"{"content":"Hi","message_index":0}"#
  private static let delta = #"{"text":"H"}"#
  private static let notFound =
    #"{"errors":[{"message":"gone","extensions":{"code":"NOT_FOUND"}}]}"#
  private static let reader = "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1"
  private static let peer = "2b8d4f19-6a05-4e73-8c1f-9d3b7e05a24c"

  /// refused is an open answered `status` coded `code`, naming `retryAfter` where one is given.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static func refused(_ status: Int, code: String, retryAfter: String? = nil)
    -> ScriptedExchange.Reply
  {
    .answer(
      status,
      headers: retryAfter.map { ["Retry-After": $0] } ?? [:],
      body: #"{"errors":[{"message":"later","extensions":{"code":"\#(code)"}}]}"#
    )
  }

  /// unavailable is an agent run's open answered 503, naming a wait of 30 seconds.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static var unavailable: ScriptedExchange.Reply {
    refused(503, code: "SERVICE_UNAVAILABLE", retryAfter: "30")
  }

  /// arrival is what an editor stream's open begins with, the roster and lock snapshots, then the
  /// arrival of `member`, and the stream then closes.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static func arrival(of member: String) -> ScriptedExchange.Reply {
    .stream(
      200,
      chunks: [
        (
          .zero,
          record(event: "presence.snapshot", data: #"{"members":[]}"#)
            + record(event: "lock.snapshot", data: #"{"locks":[]}"#)
            + record(
              event: "presence.join",
              data: #"{"user_id":"\#(member)","connected_at":"2026-05-12T09:14:07Z"}"#)
        )
      ],
      closesAt: .zero
    )
  }

  /// Naming is a session source whose one token names its user.
  private struct Naming: SessionTokenSource {
    let snapshot: SessionSnapshot

    init(_ userId: String) {
      snapshot = SessionSnapshot(token: "sess_abc", userId: userId)
    }

    func subscribe() -> AsyncStream<SessionSnapshot> {
      let snapshot = self.snapshot
      return AsyncStream { $0.yield(snapshot) }
    }
  }

  /// feed reads a collaboration stream as a caller does, through the stream the transport opens,
  /// read as `user` where one is given, until it ends, each wait drawn at its ceiling, and returns
  /// when each open was sent and what the stream ended with.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static func feed(
    _ simulation: Simulation,
    replies: [ScriptedExchange.Reply],
    request: OperationRequest = OperationRequest(
      facts: .getItineraryEvents, pathParameters: ["itinerary_id": "it"]),
    credential: Credential = session,
    asUser user: String? = nil
  ) async throws -> (sent: [Duration], failure: MountayaError?) {
    let exchange = ScriptedExchange(clock: simulation.clock, replies: replies)
    let transport = Transport.scripted(
      simulation, exchange: exchange, credential: credential, random: FixedRandom(draw: 1))
    let events: EventStream<RestSchema.CollabStreamEvent> = try transport.events(
      request, options: RequestOptions())
    var failure: MountayaError?
    do {
      for try await _ in user.map(events.reading(asUser:)) ?? events {}
    } catch let error as MountayaError {
      failure = error
    }
    return (await exchange.sent.map(\.at), failure)
  }

  /// read reads an agent run's stream until it ends or `limit` frames are read.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  private static func read(
    _ simulation: Simulation,
    replies: [ScriptedExchange.Reply],
    draw: Double = 0,
    limit: Int = 100
  ) async throws -> (frames: [String?], failure: MountayaError?, sent: [ScriptedExchange.Sent]) {
    let exchange = ScriptedExchange(clock: simulation.clock, replies: replies)
    let transport = Transport.scripted(
      simulation, exchange: exchange, credential: session, random: FixedRandom(draw: draw))
    let call = try transport.prepare(
      OperationRequest(facts: .getAgentRunEvents, pathParameters: ["run_id": "ru"]),
      accept: StreamRefusal.mediaType,
      options: RequestOptions()
    )
    let reading = EventStreamReader<RestSchema.AgentRunEvent>(transport: transport, call: call)
      .makeIterator()
    var frames: [String?] = []
    var failure: MountayaError?
    do {
      while frames.count < limit, let frame = try await reading.next() {
        frames.append(frame.id)
      }
    } catch let error as MountayaError {
      failure = error
    }
    return (frames, failure, await exchange.sent)
  }

  @Test("an open asks for the stream with the credential, and a reopen resumes from the last id")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func resumes() async throws {
    let (frames, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: [
          .stream(
            200,
            chunks: [
              (
                .zero,
                Self.record(event: "message-delta", data: Self.delta)
                  + Self.record(event: "message", data: Self.message, id: "1-0")
              )
            ], closesAt: .zero),
          .answer(404, body: Self.notFound),
        ])
    }

    #expect(frames == [nil, "1-0"])
    #expect(failure?.name == "NotFoundError")
    #expect(sent.first?.request.header("Accept") == "text/event-stream")
    #expect(sent.first?.request.header("X-Session-Token") == "sess_abc")
    #expect(sent.first?.request.header("Last-Event-ID") == nil)
    #expect(sent.last?.request.header("Last-Event-ID") == "1-0")
    // Every open names the SDK, the reopen as much as the first.
    #expect(sent.count == 2)
    #expect(
      sent.allSatisfy { $0.request.header("X-Mountaya-Client") == ClientIdentification.value })
  }

  /// `Last-Event-ID` is a header, which carries printable ASCII alone: Apple's loader would write
  /// a Latin-1 letter as one raw byte and Linux's as two, so the server would read another
  /// position, and a loader that refused it would have the stream reopen forever.
  @Test("a last id no header can carry ends the stream with a ConfigurationError, sending nothing")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func uncarriedPosition() async throws {
    let (frames, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: [
          .stream(
            200,
            chunks: [(.zero, Self.record(event: "message", data: Self.message, id: "1-caf\u{E9}"))],
            closesAt: .zero),
          .answer(404, body: Self.notFound),
        ])
    }

    #expect(frames == ["1-caf\u{E9}"], "the record itself is handed on")
    guard case .configuration(let refusal)? = failure else {
      Issue.record("the stream ended with \(String(describing: failure))")
      return
    }
    #expect(refusal.message.contains("outside printable ASCII"))
    #expect(sent.count == 1, "no open goes out with a header it cannot carry")
  }

  @Test(
    "nothing after done is read, and an unknown event is passed over without moving the position")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func endsOnDone() async throws {
    let (frames, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: [
          .stream(
            200,
            chunks: [
              (
                .zero,
                Self.record(event: "brand-new", data: "{}", id: "0-9")
                  + Self.record(event: "done", data: #"{"reason":"completed"}"#, id: "1-0")
                  + Self.record(event: "message", data: Self.message, id: "2-0")
              )
            ],
            closesAt: nil)
        ])
    }

    #expect(frames == ["1-0"])
    #expect(failure == nil)
    #expect(sent.count == 1)
  }

  @Test("every record one chunk ends is handed on in order, however many it ends")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func manyRecordsInOneChunk() async throws {
    let count = 5_000
    let ids = (0..<count).map { "\($0)-0" }
    let chunk = ids.map { Self.record(event: "message", data: Self.message, id: $0) }.joined()
    let (frames, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: [
          .stream(200, chunks: [(.zero, chunk)], closesAt: .zero),
          .answer(404, body: Self.notFound),
        ],
        limit: count + 1)
    }

    #expect(frames == ids.map(Optional.some))
    #expect(failure?.name == "NotFoundError")
    #expect(sent.last?.request.header("Last-Event-ID") == ids.last)
  }

  @Test(
    "opens without progress wait on the schedule, and the reader stops past six with the last failure"
  )
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func stops() async throws {
    let (frames, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(simulation, replies: Array(repeating: .drop(), count: 7), draw: 1)
    }
    let waits = zip(sent.dropFirst(), sent).map { $0.at - $1.at }

    #expect(frames.isEmpty)
    #expect(failure?.name == "ConnectionError")
    #expect(
      waits == [
        .milliseconds(500), .seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(8),
      ])
  }

  @Test("an open answered 429 or 503 naming a wait reopens after it with the draw, 0 seconds too")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func namedWaits() async throws {
    let (_, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: [
          Self.refused(429, code: "TOO_MANY_REQUESTS", retryAfter: "2"),
          Self.refused(503, code: "SERVICE_UNAVAILABLE", retryAfter: "0"),
          .answer(404, body: Self.notFound),
        ],
        draw: 0.5)
    }

    #expect(sent.map(\.at) == [.zero, .milliseconds(2500), .seconds(3)])
    #expect(failure?.name == "NotFoundError")
  }

  @Test("an agent run's opens answered 503 are not among the six, and its ceiling still doubles")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func unavailableOpensAreNotCounted() async throws {
    let (_, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: Array(repeating: Self.refused(503, code: "SERVICE_UNAVAILABLE"), count: 8) + [
          .answer(404, body: Self.notFound)
        ],
        draw: 1)
    }
    let waits = zip(sent.dropFirst(), sent).map { $0.at - $1.at }

    #expect(
      waits == [
        .milliseconds(500), .seconds(1), .seconds(2), .seconds(4), .seconds(8), .seconds(8),
        .seconds(8), .seconds(8),
      ])
    #expect(failure?.name == "NotFoundError")
  }

  @Test("an agent run's opens answered 503 are held to two minutes, past which it reports the 503")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func unavailableOpensAreHeldToTwoMinutes() async throws {
    let (_, failure, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: Array(repeating: Self.unavailable, count: 5) + [.answer(404, body: "")],
        draw: 1)
    }

    #expect(sent.map(\.at) == [.zero, .seconds(31), .seconds(62), .seconds(93), .seconds(124)])
    #expect(failure?.name == "ServerError")
  }

  @Test("progress and a reconnect each start an agent run's two minutes again")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func progressAndReconnectRestartTheTwoMinutes() async throws {
    let progress =
      Self.record(event: "message-delta", data: Self.delta)
      + Self.record(event: "message", data: Self.message)
    let reconnect = Self.record(event: "reconnect", data: #"{"reason":"credential-expired"}"#)
    for between in [progress, reconnect] {
      let (_, failure, sent) = try await Simulation.run { simulation in
        try await Self.read(
          simulation,
          replies: Array(repeating: Self.unavailable, count: 3)
            + [.stream(200, chunks: [(.zero, between)], closesAt: .zero)]
            + Array(repeating: Self.unavailable, count: 4) + [.answer(404, body: Self.notFound)],
          draw: 1)
      }

      #expect(
        sent.map(\.at) == [
          .zero, .seconds(31), .seconds(62), .seconds(93), .seconds(93), .seconds(124),
          .seconds(155), .seconds(186), .seconds(217),
        ])
      #expect(failure?.name == "NotFoundError")
    }
  }

  @Test("on an editor stream the reader's own join is no progress, its user named or told")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func ownArrivalIsNoProgress() async throws {
    let replies = [
      Self.arrival(of: Self.reader), Self.arrival(of: Self.reader),
      .answer(404, body: Self.notFound),
    ]
    let named = Credential.publishable(
      key: "pk_test_abc", sessionToken: .source(Naming(Self.reader)))
    let byToken = try await Simulation.run { simulation in
      try await Self.feed(simulation, replies: replies, credential: named)
    }
    let told = try await Simulation.run { simulation in
      try await Self.feed(simulation, replies: replies, asUser: Self.reader)
    }
    let tokenFirst = try await Simulation.run { simulation in
      try await Self.feed(simulation, replies: replies, credential: named, asUser: Self.peer)
    }

    for reading in [byToken, told, tokenFirst] {
      #expect(reading.sent == [.zero, .milliseconds(500), .milliseconds(1500)])
      #expect(reading.failure?.name == "NotFoundError")
    }
  }

  @Test("another member's join is progress, and so is every join a reader that knows no user reads")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func otherArrivalsAreProgress() async throws {
    let named = Credential.publishable(
      key: "pk_test_abc", sessionToken: .source(Naming(Self.reader)))
    let peer = try await Simulation.run { simulation in
      try await Self.feed(
        simulation, replies: [Self.arrival(of: Self.peer), .answer(404, body: Self.notFound)],
        credential: named)
    }
    let unnamed = try await Simulation.run { simulation in
      try await Self.feed(
        simulation, replies: [Self.arrival(of: Self.reader), .answer(404, body: Self.notFound)])
    }
    let list = try await Simulation.run { simulation in
      try await Self.feed(
        simulation, replies: [Self.arrival(of: Self.reader), .answer(404, body: Self.notFound)],
        request: OperationRequest(
          facts: .getOrganizationEvents, pathParameters: ["organization_id": "or"]),
        credential: named)
    }

    for reading in [peer, unnamed, list] {
      #expect(reading.sent == [.zero, .zero])
      #expect(reading.failure?.name == "NotFoundError")
    }
  }

  @Test("a stream that delivers nothing for 45 seconds is given up and opened again")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func stalls() async throws {
    let sent = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: [
          .stream(200, chunks: [(.seconds(10), ": beat\n\n")], closesAt: nil),
          .answer(401, body: ""),
        ]
      ).sent
    }

    #expect(sent.map(\.at) == [.zero, .seconds(55)])
  }

  @Test("a reconnect is followed at once, with the position, and is handed on to nobody")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func reconnects() async throws {
    let (frames, _, sent) = try await Simulation.run { simulation in
      try await Self.read(
        simulation,
        replies: [
          .stream(
            200,
            chunks: [
              (
                .zero,
                Self.record(event: "message", data: Self.message, id: "1-0")
                  + Self.record(event: "reconnect", data: #"{"reason":"credential-expired"}"#)
              )
            ], closesAt: nil),
          .answer(401, body: ""),
        ], draw: 1)
    }

    #expect(frames == ["1-0"])
    #expect(sent.map(\.at) == [.zero, .zero])
    #expect(sent.last?.request.header("Last-Event-ID") == "1-0")
  }

  @Test("a cancellation the exchange throws at an open ends the stream as it is, never reopened")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func exchangeCancellation() async throws {
    let sent = try await Simulation.run { simulation in
      let open = Self.record(event: "message", data: Self.message, id: "1")
      let exchange = ScriptedExchange(
        clock: simulation.clock,
        replies: [.cancel(), .stream(200, chunks: [(.zero, open)], closesAt: nil)])
      let transport = Transport.scripted(simulation, exchange: exchange, credential: Self.session)
      let call = try transport.prepare(
        OperationRequest(facts: .getAgentRunEvents, pathParameters: ["run_id": "ru"]),
        accept: StreamRefusal.mediaType,
        options: RequestOptions()
      )
      let reading = EventStreamReader<RestSchema.AgentRunEvent>(transport: transport, call: call)
        .makeIterator()
      await #expect(throws: CancellationError.self) {
        _ = try await reading.next()
      }
      #expect(try await reading.next() == nil)
      return await exchange.sent.count
    }

    #expect(sent == 1)
  }

  @Test("a credential refused locally ends the stream, and nothing is opened")
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  func refusedLocally() async throws {
    let (first, second, sent) = try await Simulation.run { simulation in
      let exchange = ScriptedExchange(clock: simulation.clock, replies: [])
      let transport = Transport.scripted(simulation, exchange: exchange)
      let call = try transport.prepare(
        OperationRequest(facts: .getAgentRunEvents, pathParameters: ["run_id": "ru"]),
        accept: StreamRefusal.mediaType,
        options: RequestOptions()
      )
      let reading = EventStreamReader<RestSchema.AgentRunEvent>(transport: transport, call: call)
        .makeIterator()
      var first: MountayaError?
      do {
        _ = try await reading.next()
      } catch let error as MountayaError {
        first = error
      }
      let second = try await reading.next()
      return (first, second, await exchange.sent.count)
    }

    #expect(first?.name == "ConfigurationError")
    #expect(second == nil)
    #expect(sent == 0)
  }
}
