import Foundation
import GateSupport
import MountayaClient
import Simulation
import Synchronization

extension PublicRunners {
  /// sessionObservable drives a `SessionTokenEngine` whose mint hands back the case's tokens in
  /// order, each only once the runner lets it land, and answers with what its snapshot and its
  /// subscribers report: `late` reads a subscription made after the first token landed, and
  /// `behind` one whose reader reads nothing while two tokens land, each a read of the stream the
  /// engine hands, which is what a subscriber reads, however often it is told.
  ///
  /// The engine sleeps on a clock whose time never moves, `HeldSeams.Still`, and reads its wall
  /// clock at `mintedAt`, a fixed instant each token expires an hour after, so no refresh falls due
  /// within a case and no case reads the machine's clock or date; every wait here is for a change
  /// the runner caused, which settles in `Quiescence`'s rounds, so a reader that is never told
  /// fails the case rather than hanging it.
  static let sessionObservable = Runner(id: "transport.session.observable", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let tokens = try input.array(at: "tokens").map { token -> String in
      guard let text = token.stringValue else {
        throw FixtureError(description: "a token is no string")
      }
      return text
    }
    let gate = MintGate(tokens: tokens, mintedAt: mintedAt)
    let engine = SessionTokenEngine(
      mint: { try await gate.mint() }, clock: HeldSeams.Still(),
      wallClock: FixedWallClock(now: mintedAt))

    switch try input.string(at: "ask") {
    case "read":
      return .value(
        .object([
          OrderedJSON.Member(
            key: "token", value: engine.snapshot.token.map(OrderedJSON.string) ?? .null)
        ])
      )

    case "observe":
      let reader = Reader(engine.subscribe())
      let before = engine.snapshot.token
      await gate.release()
      let notified = await reader.waits { $0.contains("sess_first") || $0.contains(tokens[0]) }
      return .value(
        .object([
          OrderedJSON.Member(
            key: "after", value: engine.snapshot.token.map(OrderedJSON.string) ?? .null),
          OrderedJSON.Member(key: "before", value: before.map(OrderedJSON.string) ?? .null),
          OrderedJSON.Member(key: "notified", value: .bool(notified)),
        ])
      )

    case "stable":
      let reader = Reader(engine.subscribe())
      let first = engine.snapshot
      let second = engine.snapshot
      await gate.release()
      _ = await reader.waits { $0.contains(tokens[0]) }
      let changed = engine.snapshot
      reader.stop()
      return .value(
        .object([
          OrderedJSON.Member(key: "changedAfterAChange", value: .bool(changed != second)),
          OrderedJSON.Member(key: "sameBetweenChanges", value: .bool(first == second)),
        ])
      )

    case "unsubscribe":
      guard tokens.count >= 2 else {
        throw FixtureError(description: "the case mints fewer than two tokens")
      }
      let leaving = Reader(engine.subscribe())
      let staying = Reader(engine.subscribe())
      await gate.release()
      let whileSubscribed = await leaving.waits { $0.contains(tokens[0]) }
      _ = await staying.waits { $0.contains(tokens[0]) }
      let toldBefore = leaving.tokens.count
      leaving.stop()
      engine.refresh()
      await gate.release()
      let remaining = await staying.waits { $0.contains(tokens[1]) }
      let toldAfter = leaving.tokens.count
      staying.stop()
      return .value(
        .object([
          OrderedJSON.Member(
            key: "after", value: engine.snapshot.token.map(OrderedJSON.string) ?? .null),
          OrderedJSON.Member(key: "notifiedAfterUnsubscribe", value: .bool(toldAfter > toldBefore)),
          OrderedJSON.Member(key: "notifiedWhileSubscribed", value: .bool(whileSubscribed)),
          OrderedJSON.Member(key: "remainingSubscriberNotified", value: .bool(remaining)),
        ])
      )

    case "late":
      guard tokens.count >= 2 else {
        throw FixtureError(description: "the case mints fewer than two tokens")
      }
      let early = Reader(engine.subscribe())
      await gate.release()
      _ = await early.waits { $0.contains(tokens[0]) }
      let late = Reader(engine.subscribe())
      _ = await late.waits { !$0.isEmpty }
      let firstRead = late.tokens.first ?? nil
      engine.refresh()
      await gate.release()
      _ = await late.waits { $0.contains(tokens[1]) }
      let lastRead = late.tokens.last ?? nil
      early.stop()
      late.stop()
      return .value(
        .object([
          OrderedJSON.Member(key: "firstRead", value: firstRead.map(OrderedJSON.string) ?? .null),
          OrderedJSON.Member(key: "lastRead", value: lastRead.map(OrderedJSON.string) ?? .null),
        ])
      )

    case "behind":
      guard tokens.count >= 3 else {
        throw FixtureError(description: "the case mints fewer than three tokens")
      }
      // One reader, read by hand: it reads up to the first token, then nothing while two more
      // land, then once.
      var reader = engine.subscribe().makeAsyncIterator()
      await gate.release()
      var before: String?
      while let snapshot = await reader.next() {
        if snapshot.token == tokens[0] {
          before = snapshot.token
          break
        }
      }
      for token in tokens[1...2] {
        engine.refresh()
        await gate.release()
        guard
          await settles(
            observing: { engine.snapshot },
            holding: { engine.snapshot.token == token && !engine.snapshot.isMinting })
        else {
          throw FixtureError(description: "the engine never held `\(token)`")
        }
      }
      let after = await reader.next()?.token
      return .value(
        .object([
          OrderedJSON.Member(
            key: "readAfterFallingBehind", value: after.map(OrderedJSON.string) ?? .null),
          OrderedJSON.Member(
            key: "readBeforeFallingBehind", value: before.map(OrderedJSON.string) ?? .null),
        ])
      )

    case let other:
      throw FixtureError(description: "no ask is called `\(other)`")
    }
  }

  /// settles lets what the runner set going come to rest, in `Quiescence`'s rounds reading
  /// `observed`, and returns whether `condition` holds then.
  static func settles(
    observing observed: @Sendable () -> SessionSnapshot, holding condition: @Sendable () -> Bool
  ) async -> Bool {
    await Quiescence.settle(observing: observed)
    return condition()
  }

  /// mintedAt is the instant the session runners' wall clock reads, 2023-11-14T22:13:20Z.
  static let mintedAt = Date(timeIntervalSince1970: 1_700_000_000)

  /// MintGate hands back one token per mint, each expiring an hour after `mintedAt` and handed
  /// back only once the runner releases it.
  actor MintGate {
    private var tokens: [String]
    private let mintedAt: Date
    private var released = 0
    private var waiting: [CheckedContinuation<Void, Never>] = []

    init(tokens: [String], mintedAt: Date) {
      self.tokens = tokens
      self.mintedAt = mintedAt
    }

    func mint() async throws -> RestSchema.Session {
      if released == 0 {
        await withCheckedContinuation { waiting.append($0) }
      }
      released -= 1
      guard !tokens.isEmpty else {
        throw FixtureError(description: "the engine minted more tokens than the case holds")
      }
      return RestSchema.Session(
        expires_at: mintedAt.addingTimeInterval(3600),
        user_id: "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1",
        token: tokens.removeFirst()
      )
    }

    func release() {
      released += 1
      if !waiting.isEmpty {
        waiting.removeFirst().resume()
      }
    }
  }

  /// Reader reads one subscription in a task of its own, keeping each token it is told of.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  final class Reader: Sendable {
    private let told = Shared<[String?]>([])
    private let task: Task<Void, Never>

    init(_ subscription: AsyncStream<SessionSnapshot>) {
      let told = self.told
      task = Task {
        for await snapshot in subscription {
          told.update { $0.append(snapshot.token) }
        }
      }
    }

    var tokens: [String?] {
      told.value
    }

    /// waits returns whether the reader was told what `condition` looks for once what it is told
    /// has come to rest, in `Quiescence`'s rounds.
    func waits(for condition: @escaping @Sendable ([String?]) -> Bool) async -> Bool {
      let told = self.told
      await Quiescence.settle { told.value }
      return condition(told.value)
    }

    /// stop ends the subscription.
    func stop() {
      task.cancel()
    }
  }

  /// sessionFirstToken makes a request whose session token is read per request, from a source
  /// the runner moves through the case's states on a simulation's clock or from a function, and
  /// answers with whether and when the request went out, under which token, or how it was
  /// refused.
  static let sessionFirstToken = Runner(id: "transport.session.first-token", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    let input = fixtureCase.input
    let timeout = Duration.milliseconds(try input.number(at: "timeoutMs"))
    let declaration = OperationDeclaration(
      operationId: "readThing",
      method: "GET",
      credentials: CredentialDeclaration(requiresSession: try input.flag(at: "requiresSession"))
    )
    let session = try input.string(at: "session")
    let initial = try snapshot(input["initial"] ?? .object([]))
    let steps = try (input["steps"]?.elements ?? []).map { step in
      (at: Duration.milliseconds(try step.number(at: "atMs")), snapshot: try snapshot(step))
    }
    let answers = try input.optionalString(at: "answers")

    let (sentAt, token, refusal, refusedAt) = try await Simulation.run {
      simulation -> (Duration?, String?, MountayaError?, Duration?) in
      let exchange = Scripted.Exchange(
        clock: simulation.clock, replies: [.answer(status: 200, body: Scripted.emptySuccess)])
      let source = ScriptedSource(initial)
      let sessionToken: SessionToken
      switch session {
      case "source": sessionToken = .source(source)
      case "function": sessionToken = .function { answers }
      default: throw FixtureError(description: "no session is called `\(session)`")
      }
      let client = try Scripted.client(
        simulation,
        exchange: exchange,
        credential: .publishable(key: "pk_test_abc", sessionToken: sessionToken),
        retry: noRetries
      )
      return try await withThrowingTaskGroup(
        of: (Duration?, String?, MountayaError?, Duration?)?.self
      ) { group in
        group.addTask {
          for step in steps {
            try await simulation.clock.sleep(until: VirtualClock.Instant(offset: step.at))
            source.move(to: step.snapshot)
          }
          return nil
        }
        group.addTask {
          do {
            let _: Response<JSONValue, JSONValue?> = try await client.send(
              declaration, path: "/v1/things", options: RequestOptions(timeout: timeout))
            let sent = await exchange.sent.first
            return (sent?.at, sent?.request.header("X-Session-Token"), nil, nil)
          } catch let error as MountayaError {
            return (nil, nil, error, simulation.elapsed)
          }
        }
        while let next = try await group.next() {
          if let settled = next {
            group.cancelAll()
            return settled
          }
        }
        throw FixtureError(description: "the request never settled")
      }
    }
    var causedByMint = false
    if case .configuration(let error)? = refusal {
      causedByMint = error.cause is MintFailure
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "causedByMint", value: .bool(causedByMint)),
        OrderedJSON.Member(key: "elapsedMs", value: .milliseconds(sentAt ?? refusedAt ?? .zero)),
        OrderedJSON.Member(key: "refused", value: refusal.map { .string($0.name) } ?? .null),
        OrderedJSON.Member(key: "sent", value: .bool(sentAt != nil)),
        OrderedJSON.Member(key: "sessionToken", value: token.map(OrderedJSON.string) ?? .null),
      ])
    )
  }

  /// MintFailure is the failure of a mint the case says failed.
  struct MintFailure: Error {}

  /// snapshot reads one of the case's states of a source.
  private static func snapshot(_ state: OrderedJSON) throws -> SessionSnapshot {
    SessionSnapshot(
      token: try state.optionalString(at: "token"),
      isMinting: try state.flag(at: "loading"),
      error: try state.flag(at: "failed") ? MintFailure() : nil
    )
  }

  /// ScriptedSource is a session source of the application's own, which the runner moves from
  /// state to state, telling each of its subscribers.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  final class ScriptedSource: SessionTokenSource {
    private struct State: Sendable {
      var snapshot: SessionSnapshot
      var subscribers: [AsyncStream<SessionSnapshot>.Continuation] = []
    }

    private let state: Mutex<State>

    init(_ initial: SessionSnapshot) {
      state = Mutex(State(snapshot: initial))
    }

    var snapshot: SessionSnapshot {
      state.withLock { $0.snapshot }
    }

    func subscribe() -> AsyncStream<SessionSnapshot> {
      AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
        state.withLock { state in
          state.subscribers.append(continuation)
          continuation.yield(state.snapshot)
        }
      }
    }

    func move(to snapshot: SessionSnapshot) {
      state.withLock { state in
        state.snapshot = snapshot
        for subscriber in state.subscribers {
          subscriber.yield(snapshot)
        }
      }
    }
  }
}
