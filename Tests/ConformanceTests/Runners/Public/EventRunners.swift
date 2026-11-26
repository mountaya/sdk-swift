import Foundation
import GateSupport
import MountayaClient
import Simulation

extension PublicRunners {
  /// session is a credential every stream's open takes: a publishable key and a session token.
  static let session = Credential.publishable(key: "pk_test_abc", sessionToken: "sess_abc")

  /// aStream is a stream this build prints no method for, by its declaration.
  static let aStream = OperationDeclaration(
    operationId: "followThings",
    method: "GET",
    idempotent: true,
    credentials: CredentialDeclaration(actingUser: .required, requiresSession: true)
  )

  /// sse writes one record of a stream: its `event:`, its `id:` and its `data:`, each where the
  /// frame names one, and the empty line that ends it.
  static func sse(event: String?, id: String?, data: String?) -> String {
    var text = ""
    if let event {
      text += "event: \(event)\n"
    }
    if let id {
      text += "id: \(id)\n"
    }
    if let data {
      text += "data: \(data)\n"
    }
    return text + "\n"
  }

  /// eventsFraming opens a stream by its declaration on a scripted exchange whose first open
  /// writes the case's chunks and closes, and answers with the records the stream handed on and
  /// the `Last-Event-ID` the reopen that follows sent, the reopen being answered with a 404 that
  /// ends the stream.
  static let eventsFraming = Runner(id: "transport.events.framing", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let chunks = try fixtureCase.input.array(at: "chunks").map { chunk -> Data in
      if let text = chunk.stringValue {
        return Data(text.utf8)
      }
      guard let bytes = chunk.elements else {
        throw FixtureError(description: "a chunk is neither text nor bytes")
      }
      return Data(
        try bytes.map { byte -> UInt8 in
          guard let value = byte.numberValue.flatMap({ UInt8(exactly: $0) }) else {
            throw FixtureError(description: "a byte is no number from 0 to 255")
          }
          return value
        }
      )
    }
    let (records, resumed) = try await Simulation.run { simulation -> ([EventRecord], String?) in
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: [
          .stream(
            status: 200,
            body: Scripted.BodyScript(chunks: chunks.map { (.zero, $0) }, end: .closes(at: .zero))
          ),
          .answer(status: 404, body: Scripted.errorBody(code: "NOT_FOUND")),
        ]
      )
      let client = try Scripted.client(simulation, exchange: exchange, credential: session)
      var records: [EventRecord] = []
      do {
        for try await frame in try client.events(aStream, path: "/v1/things/events") {
          records.append(frame.event)
        }
      } catch MountayaError.api(let error) where error.kind == .notFound {
        // The reopen's 404 ends the stream, which is where the case stops reading.
      }
      let sent = await exchange.sent
      guard sent.count == 2 else {
        throw FixtureError(description: "the stream was opened \(sent.count) times, not twice")
      }
      return (records, sent[1].request.header("Last-Event-ID"))
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "lastEventId", value: resumed.map(OrderedJSON.string) ?? .null),
        OrderedJSON.Member(
          key: "records",
          value: .array(
            records.map { record in
              .object([
                OrderedJSON.Member(key: "data", value: .string(record.data)),
                OrderedJSON.Member(key: "event", value: .string(record.event ?? "")),
                OrderedJSON.Member(key: "id", value: .string(record.id ?? "")),
              ])
            }
          )
        ),
      ])
    )
  }

  /// Followed is what a reader of a printed stream method saw: the events in order, each with
  /// its type, and how the iteration ended.
  struct Followed: Sendable {
    let types: [String]
    let reason: String?
    let surfaced: [String]
    let ended: Bool
    let failure: MountayaError?
  }

  /// HandlerFailure is the failure a reader's own handler raises.
  struct HandlerFailure: Error {}

  /// follow reads an agent run's stream or a collaboration feed through its printed method,
  /// handing each event to a handler that fails on the one at `failsAt`, where a case names one.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func follow(
    _ stream: String,
    client: Mountaya,
    failsAt: Int? = nil
  ) async throws -> Followed {
    var types: [String] = []
    var reason: String?
    var surfaced: [String] = []
    var ended = false
    var failure: MountayaError?
    do {
      switch stream {
      case "agent":
        for try await frame in try client.agent.runs.getAgentRunEvents(run_id: "ru") {
          types.append(try type(of: frame.event))
          if types.count - 1 == failsAt {
            throw HandlerFailure()
          }
          switch frame.event {
          case .AgentDoneEvent(let done): reason = done.reason.rawValue
          case .AgentErrorEvent(let error): surfaced.append(error.code.rawValue)
          case .AgentBudgetExhaustedEvent: surfaced.append("budget-exhausted")
          default: break
          }
        }
      case "collaboration":
        for try await frame in try client.studio.collab.getItineraryEvents(itinerary_id: "it") {
          types.append(try type(of: frame.event))
          if types.count - 1 == failsAt {
            throw HandlerFailure()
          }
        }
      default:
        throw FixtureError(description: "no stream is called `\(stream)`")
      }
      ended = true
    } catch let error as MountayaError {
      failure = error
    } catch is HandlerFailure {
      // The handler's own failure ends the reading, and is no failure of the stream.
    }
    return Followed(
      types: types, reason: reason, surfaced: surfaced, ended: ended, failure: failure)
  }

  /// type returns the `type` an event writes itself with.
  static func type(of event: some Encodable) throws -> String {
    let written = try OrderedJSON.parse(
      String(decoding: try JSONEncoder().encode(event), as: UTF8.self))
    guard let type = written["type"]?.stringValue else {
      throw FixtureError(description: "an event writes no type")
    }
    return type
  }

  /// eventsTerminal reads the case's frames off one open of a printed stream method, and answers
  /// with where the stream ended and how, what it surfaced, the events it handed its reader by
  /// the type each writes itself with, and whether and from where it opened the stream again, the
  /// reopen being answered with a 404 that ends it.
  static let eventsTerminal = Runner(id: "transport.events.terminal", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let stream = try input.string(at: "stream")
    let frames = try input.array(at: "frames")
    var text = ""
    for frame in frames {
      text += sse(
        event: try frame.optionalString(at: "event"),
        id: try frame.optionalString(at: "id"),
        data: try frame["data"].map(Scripted.compact)
      )
    }
    let failsAt = try input.optionalInteger(at: "handlerFailsAt")
    let body = Data(text.utf8)
    let (followed, sent) = try await Simulation.run {
      simulation -> (Followed, [Scripted.Exchange.Sent]) in
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: [
          .stream(
            status: 200, body: Scripted.BodyScript(chunks: [(.zero, body)], end: .closes(at: .zero))
          ),
          .answer(status: 404, body: Scripted.errorBody(code: "NOT_FOUND")),
        ]
      )
      let client = try Scripted.client(simulation, exchange: exchange, credential: session)
      let followed = try await follow(stream, client: client, failsAt: failsAt)
      return (followed, await exchange.sent)
    }
    var endedAt: OrderedJSON = .null
    if stream == "agent", followed.reason != nil {
      guard
        let index = try frames.firstIndex(where: { try $0.optionalString(at: "event") == "done" })
      else {
        throw FixtureError(description: "the stream ended with no `done` among its frames")
      }
      endedAt = .number(Double(index))
    }
    let reopened = sent.count > 1
    return .value(
      .object([
        OrderedJSON.Member(key: "endedAt", value: endedAt),
        OrderedJSON.Member(key: "handed", value: .array(followed.types.map(OrderedJSON.string))),
        OrderedJSON.Member(key: "reason", value: followed.reason.map(OrderedJSON.string) ?? .null),
        OrderedJSON.Member(key: "reopened", value: .bool(reopened)),
        OrderedJSON.Member(
          key: "resumedFrom",
          value: reopened
            ? sent[1].request.header("Last-Event-ID").map(OrderedJSON.string) ?? .null : .null
        ),
        OrderedJSON.Member(
          key: "surfaced", value: .array(followed.surfaced.map(OrderedJSON.string))),
      ])
    )
  }

  /// eventsOpenErrors opens a printed stream method whose open fails as the case says, and
  /// answers with the error that failure raised and whether it ended the stream.
  ///
  /// An open that ends the stream throws its error from the iteration. One that reopens it does
  /// not: an agent run's stream is then answered the same way until it stops on its ceiling, or
  /// two minutes after its first 503, and throws the failure its last open failed with, every wait
  /// drawn at its ceiling so that those minutes pass, and a collaboration feed, which never stops
  /// on its own, is answered with a 404 on its reopen, the error the case's answer raises being
  /// read off the same answer to a request, which is the contract's statement of what it is.
  static let eventsOpenErrors = Runner(id: "transport.events.open-errors", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let stream = try input.string(at: "stream")
    let refusedLocally = try input.flag(at: "refusedLocally")
    let reply: Scripted.Reply =
      try input.optionalInteger(at: "status").map { status in
        .answer(
          status: status, body: Scripted.errorBody(code: try input.optionalString(at: "code")))
      } ?? .drop()
    let (followed, opens, requested) = try await Simulation.run {
      simulation -> (Followed, Int, MountayaError?) in
      let notFound = Scripted.Reply.answer(status: 404, body: Scripted.errorBody(code: "NOT_FOUND"))
      let exchange = Scripted.Exchange(
        clock: simulation.clock,
        replies: stream == "collaboration" ? [reply, notFound] : [],
        exhausted: reply
      )
      let credential: Credential = refusedLocally ? .publishable(key: "pk_test_abc") : session
      let client = try Scripted.client(
        simulation, exchange: exchange, credential: credential, random: Scripted.Random(draw: 1))
      let followed = try await follow(stream, client: client)
      let opens = await exchange.sent.count
      var requested: MountayaError?
      if stream == "collaboration", opens > 1 {
        let request = Scripted.Exchange(clock: simulation.clock, replies: [reply])
        let requester = try Scripted.client(
          simulation, exchange: request, credential: session, retry: noRetries)
        do {
          let _: Response<JSONValue, JSONValue?> = try await requester.send(
            aRead, path: "/v1/things")
        } catch let error as MountayaError {
          requested = error
        }
      }
      return (followed, opens, requested)
    }
    let ends: Bool
    let error: MountayaError?
    switch stream {
    case "agent":
      ends = opens <= 1
      error = followed.failure
    default:
      ends = opens <= 1
      error = ends ? followed.failure : requested
    }
    guard let error else {
      throw FixtureError(description: "the open raised nothing")
    }
    var code: String?
    if case .api(let apiError) = error {
      code = apiError.code?.rawValue
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "class", value: .string(error.name)),
        OrderedJSON.Member(key: "code", value: code.map(OrderedJSON.string) ?? .null),
        OrderedJSON.Member(key: "ends", value: .bool(ends)),
      ])
    )
  }

  /// eventsMethodRefusal sends a buffered call by its declaration with the case's `Accept`, and
  /// answers with the refusal it met and whether anything was sent.
  static let eventsMethodRefusal = Runner(id: "transport.events.method-refusal", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let accept = try fixtureCase.input.string(at: "accept")
    let (refusal, sent) = try await Simulation.run { simulation -> (MountayaError?, Int) in
      let exchange = Scripted.Exchange(
        clock: simulation.clock, replies: [.answer(status: 200, body: Scripted.emptySuccess)])
      let client = try Scripted.client(simulation, exchange: exchange)
      var refusal: MountayaError?
      do {
        let _: Response<JSONValue, JSONValue?> = try await client.send(
          aRead, path: "/v1/things", headers: ["Accept": accept])
      } catch let error as MountayaError {
        refusal = error
      }
      return (refusal, await exchange.sent.count)
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "refused", value: refusal.map { .string($0.name) } ?? .null),
        OrderedJSON.Member(key: "sent", value: .bool(sent > 0)),
      ])
    )
  }
}
