import Foundation
import GateSupport
import MountayaClient
import Simulation
import Synchronization

/// Scripted is what the public runners put behind a client in place of the network and the
/// platform: an exchange that answers from a script, on a simulation's clock, and draws that are
/// the fixture's own. Everything here is written against the published seams, so a consumer's
/// test can do the same.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
enum Scripted {
  /// Reply is how the exchange answers one attempt.
  enum Reply: Sendable {
    /// answer is an answer that arrives `after` the attempt was sent, its body whole.
    case answer(
      status: Int, headers: [String: String] = [:], body: Data = Data(), after: Duration = .zero)
    /// drop is a request that never arrived, the connection dropping `after` it was sent.
    case drop(after: Duration = .zero)
    /// never is an attempt nothing ever answers.
    case never
    /// stream is an answer whose body is read as `body` says, from the moment it arrives.
    case stream(
      status: Int, headers: [String: String] = [:], body: BodyScript, after: Duration = .zero)
  }

  /// BodyScript is a body that arrives a chunk at a time, each `at` its offset from the answer,
  /// and then ends as `end` says.
  struct BodyScript: Sendable {
    /// End is how a body ends once its chunks are read.
    enum End: Sendable {
      /// closes is a body the far side closes at `at`, from the answer.
      case closes(at: Duration)
      /// drops is a body that breaks off at `at`, from the answer.
      case drops(at: Duration)
      /// staysOpen is a body that delivers nothing more and never ends.
      case staysOpen
    }

    let chunks: [(at: Duration, bytes: Data)]
    let end: End

    init(chunks: [(at: Duration, bytes: Data)], end: End) {
      self.chunks = chunks
      self.end = end
    }
  }

  /// Dropped is the failure of a connection the script drops.
  struct Dropped: Error {}

  /// Exchange answers each attempt with the next reply of its script, and records what each
  /// attempt sent and when.
  actor Exchange: HTTPExchange {
    /// Sent is one attempt as it left the client.
    struct Sent: Sendable {
      let request: ExchangeRequest
      /// at is when the attempt was sent, from the simulation's start.
      let at: Duration
    }

    /// Ended is when an attempt's answer ended, from the simulation's start.
    struct Ended: Sendable {
      let attempt: Int
      let at: Duration
    }

    private var replies: [Reply]
    private let exhausted: Reply
    private let clock: VirtualClock
    private let onExhausted: (@Sendable () -> Void)?
    private(set) var sent: [Sent] = []
    private(set) var ended: [Ended] = []

    /// Creates an exchange answering with `replies` in order, and with `exhausted` once they are
    /// spent, telling `onExhausted` of every attempt the script did not foresee.
    init(
      clock: VirtualClock,
      replies: [Reply],
      exhausted: Reply = .never,
      onExhausted: (@Sendable () -> Void)? = nil
    ) {
      self.clock = clock
      self.replies = replies
      self.exhausted = exhausted
      self.onExhausted = onExhausted
    }

    /// lastActivity returns when an attempt last delivered anything or ended, from the
    /// simulation's start.
    func lastActivity(of attempt: Int) -> Duration? {
      ended.filter { $0.attempt == attempt }.map(\.at).max()
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      let attempt = sent.count
      sent.append(Sent(request: request, at: clock.now.offset))
      let reply: Reply
      if replies.isEmpty {
        reply = exhausted
        onExhausted?()
      } else {
        reply = replies.removeFirst()
      }
      switch reply {
      case .answer(let status, let headers, let body, let after):
        try await clock.sleep(for: after)
        ended.append(Ended(attempt: attempt, at: clock.now.offset))
        return ExchangeResponse(status: status, headers: headers, body: ExchangeBody(body))
      case .drop(let after):
        try await clock.sleep(for: after)
        ended.append(Ended(attempt: attempt, at: clock.now.offset))
        throw Dropped()
      case .never:
        do {
          try await clock.sleep(until: VirtualClock.Instant(offset: .seconds(1_000_000_000)))
        } catch {
          ended.append(Ended(attempt: attempt, at: clock.now.offset))
          throw error
        }
        throw Dropped()
      case .stream(let status, let headers, let script, let after):
        try await clock.sleep(for: after)
        ended.append(Ended(attempt: attempt, at: clock.now.offset))
        let body = Body(script: script, clock: clock, exchange: self, attempt: attempt)
        return ExchangeResponse(
          status: status,
          headers: headers,
          body: ExchangeBody { try await body.next() }
        )
      }
    }

    /// record notes when an attempt's body ended.
    func record(_ attempt: Int, endedAt at: Duration) {
      ended.append(Ended(attempt: attempt, at: at))
    }
  }

  /// Body reads a body script on the simulation's clock.
  actor Body {
    private let script: BodyScript
    private let clock: VirtualClock
    private let opened: Duration
    private let exchange: Exchange
    private let attempt: Int
    private var next = 0
    private var isOver = false

    init(script: BodyScript, clock: VirtualClock, exchange: Exchange, attempt: Int) {
      self.script = script
      self.clock = clock
      self.opened = clock.now.offset
      self.exchange = exchange
      self.attempt = attempt
    }

    func next() async throws -> Data? {
      guard !isOver else { return nil }
      if next < script.chunks.count {
        let chunk = script.chunks[next]
        next += 1
        do {
          try await clock.sleep(until: VirtualClock.Instant(offset: opened + chunk.at))
        } catch {
          await exchange.record(attempt, endedAt: clock.now.offset)
          throw error
        }
        await exchange.record(attempt, endedAt: clock.now.offset)
        return chunk.bytes
      }
      switch script.end {
      case .closes(let at):
        try await clock.sleep(until: VirtualClock.Instant(offset: opened + at))
        isOver = true
        await exchange.record(attempt, endedAt: clock.now.offset)
        return nil
      case .drops(let at):
        try await clock.sleep(until: VirtualClock.Instant(offset: opened + at))
        isOver = true
        await exchange.record(attempt, endedAt: clock.now.offset)
        throw Dropped()
      case .staysOpen:
        do {
          try await clock.sleep(until: VirtualClock.Instant(offset: .seconds(1_000_000_000)))
        } catch {
          await exchange.record(attempt, endedAt: clock.now.offset)
          throw error
        }
        return nil
      }
    }
  }

  /// Random draws the fixture's own number before every wait, and keys from a source that may
  /// be missing.
  struct Random: RandomSource {
    let draw: Double
    let keys: Bool
    /// key is the one key every draw answers, or nil for a fresh one each time.
    let key: UUID?

    /// drawn counts the fresh keys drawn in the process, which numbers each one, so every draw
    /// differs and every run draws the same keys.
    private static let drawn = Mutex<UInt64>(0)

    init(draw: Double = 0, keys: Bool = true, key: UUID? = nil) {
      self.draw = draw
      self.keys = keys
      self.key = key
    }

    func unitDraw() -> Double {
      draw
    }

    func cryptographicUuid() -> UUID? {
      guard keys else { return nil }
      if let key { return key }
      return Scripted.key(
        Self.drawn.withLock { count in
          count += 1
          return count
        })
    }
  }

  /// key is the version 4 key numbered `number`, its last eight bytes the number's.
  static func key(_ number: UInt64) -> UUID {
    let bytes = withUnsafeBytes(of: number.bigEndian) { Array($0) }
    return UUID(
      uuid: (
        0, 0, 0, 0, 0, 0, 0x40, 0, 0x80, 0, bytes[2], bytes[3], bytes[4], bytes[5], bytes[6],
        bytes[7]
      ))
  }

  /// Wall reads the wall clock off a simulation: `start`, plus the time the simulation has run.
  struct Wall: WallClock {
    let clock: VirtualClock
    /// start is the instant the simulation starts at, the Unix epoch unless a runner names another.
    var start = Date(timeIntervalSince1970: 0)

    var now: Date {
      let (seconds, attoseconds) = clock.now.offset.components
      return start.addingTimeInterval(TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18)
    }
  }

  /// Reports collects what a client's `onResponse` hook is told.
  final class Reports: Sendable {
    private let reports = Shared<[ResponseReport]>([])

    var all: [ResponseReport] {
      reports.value
    }

    func record(_ report: ResponseReport) {
      reports.update { $0.append(report) }
    }
  }

  /// errorBody is a failure envelope with one entry coded `code`, or none where it is nil.
  static func errorBody(code: String?, message: String = "scripted") -> Data {
    guard let code else { return Data(#"{"errors":[]}"#.utf8) }
    return json(
      .object([
        OrderedJSON.Member(
          key: "errors",
          value: .array([
            .object([
              OrderedJSON.Member(
                key: "extensions",
                value: .object([OrderedJSON.Member(key: "code", value: .string(code))])
              ),
              OrderedJSON.Member(key: "message", value: .string(message)),
            ])
          ])
        )
      ])
    )
  }

  /// client is a client sending through `exchange` on the simulation's clock and its wall clock,
  /// drawing what `random` draws, and telling `reports` of every attempt an answer came back to.
  static func client(
    _ simulation: Simulation,
    exchange: any HTTPExchange,
    credential: Credential = .publishable(key: "pk_test_abc"),
    retry: RetryPolicy = .standard,
    timeout: Duration = .seconds(30),
    random: Random = Random(),
    reports: Reports? = nil
  ) throws -> Mountaya {
    var hook: (@Sendable (ResponseReport) -> Void)?
    if let reports {
      hook = { report in reports.record(report) }
    }
    return try Mountaya(
      credential: credential,
      retry: retry,
      timeout: timeout,
      onResponse: hook,
      exchange: exchange,
      clock: simulation.clock,
      random: random,
      wallClock: Wall(clock: simulation.clock, start: HeldSeams.epoch)
    )
  }

  /// ordered writes an open JSON value as the harness compares one.
  static func ordered(_ value: JSONValue) -> OrderedJSON {
    switch value {
    case .null:
      return .null
    case .bool(let flag):
      return .bool(flag)
    case .number(let number):
      return .number(number)
    case .string(let text):
      return .string(text)
    case .array(let elements):
      return .array(elements.map { ordered($0) })
    case .object(let members):
      let sorted = members.sorted { $0.key < $1.key }
      return .object(sorted.map { OrderedJSON.Member(key: $0.key, value: ordered($0.value)) })
    }
  }

  /// compact writes a fixture's value as JSON on one line, as a `data:` line carries it.
  static func compact(_ value: OrderedJSON) throws -> String {
    let read = try JSONDecoder().decode(JSONValue.self, from: Data(value.serialized().utf8))
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return String(decoding: try encoder.encode(read), as: UTF8.self)
  }

  /// emptySuccess is an envelope whose `data` is null.
  static let emptySuccess = Data(#"{"data":null}"#.utf8)

  /// json writes a fixture's value as the bytes of a body.
  static func json(_ value: OrderedJSON) -> Data {
    Data(value.serialized().utf8)
  }

  /// className names a call's failure as the contract does, or `aborted` for the caller's own
  /// cancellation.
  static func className(_ error: any Error) -> String {
    if error is CancellationError {
      return "aborted"
    }
    if let error = error as? MountayaError {
      return error.name
    }
    return "\(type(of: error))"
  }

  /// milliseconds writes a duration as a number of milliseconds.
  static func milliseconds(_ duration: Duration) -> OrderedJSON {
    .milliseconds(duration)
  }
}

/// Shared is a value a runner's closures read and change from any task, under a lock.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
final class Shared<Value: Sendable>: Sendable {
  private let mutex: Mutex<Value>

  init(_ value: Value) {
    mutex = Mutex(value)
  }

  var value: Value {
    mutex.withLock { $0 }
  }

  func update(_ change: (inout Value) -> Void) {
    mutex.withLock { change(&$0) }
  }
}
