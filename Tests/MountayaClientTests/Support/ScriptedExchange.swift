import Foundation
import Simulation
import Synchronization

@testable import MountayaClient

/// ScriptedExchange answers each attempt with the next reply of its script, on a simulation's
/// clock, and records what each attempt sent and when.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
actor ScriptedExchange: HTTPExchange {
  /// Reply is how one attempt is answered.
  enum Reply: Sendable {
    /// answer arrives `after` the attempt, its body whole.
    case answer(Int, headers: [String: String] = [:], body: String = "", after: Duration = .zero)
    /// drop is a connection that drops `after` the attempt.
    case drop(after: Duration = .zero)
    /// cancel is an attempt the platform reports cancelled `after` it, as `SystemExchange` reports
    /// `URLError(.cancelled)`, while the calling task runs on.
    case cancel(after: Duration = .zero)
    /// never is an attempt nothing answers.
    case never
    /// stream arrives at once, its body read a chunk at each offset, then closing at `closesAt`,
    /// or staying open where it is nil.
    case stream(Int, chunks: [(at: Duration, text: String)], closesAt: Duration?)
  }

  /// Dropped is the failure of a dropped connection.
  struct Dropped: Error {}

  /// Sent is one attempt as it left the client.
  struct Sent: Sendable {
    let request: ExchangeRequest
    let at: Duration
  }

  private var replies: [Reply]
  private let exhausted: Reply
  private let clock: VirtualClock
  private(set) var sent: [Sent] = []

  init(clock: VirtualClock, replies: [Reply], exhausted: Reply = .never) {
    self.clock = clock
    self.replies = replies
    self.exhausted = exhausted
  }

  func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
    sent.append(Sent(request: request, at: clock.now.offset))
    let reply = replies.isEmpty ? exhausted : replies.removeFirst()
    switch reply {
    case .answer(let status, let headers, let body, let after):
      try await clock.sleep(for: after)
      return ExchangeResponse(status: status, headers: headers, body: ExchangeBody(Data(body.utf8)))
    case .drop(let after):
      try await clock.sleep(for: after)
      throw Dropped()
    case .cancel(let after):
      try await clock.sleep(for: after)
      throw CancellationError()
    case .never:
      try await clock.sleep(for: .seconds(1_000_000_000))
      throw Dropped()
    case .stream(let status, let chunks, let closesAt):
      let opened = clock.now.offset
      let clock = self.clock
      let remaining = Mutex(chunks[...])
      let body = ExchangeBody {
        if let chunk = remaining.withLock({ $0.popFirst() }) {
          try await clock.sleep(until: VirtualClock.Instant(offset: opened + chunk.at))
          return Data(chunk.text.utf8)
        }
        guard let closesAt else {
          try await clock.sleep(for: .seconds(1_000_000_000))
          return nil
        }
        try await clock.sleep(until: VirtualClock.Instant(offset: opened + closesAt))
        return nil
      }
      return ExchangeResponse(status: status, body: body)
    }
  }
}

/// FixedRandom draws one number before every wait, and keys from a source that may be missing.
struct FixedRandom: RandomSource {
  var draw: Double = 0
  var keys = true

  func unitDraw() -> Double {
    draw
  }

  func cryptographicUuid() -> UUID? {
    keys ? UUID(uuidString: "6f1c2a9e-3b4d-4e5f-8a6b-7c8d9e0f1a2b") : nil
  }
}

/// SimulatedWallClock reads the wall clock off a simulation: the epoch plus the time it has run.
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
struct SimulatedWallClock: WallClock {
  let clock: VirtualClock

  var now: Date {
    let (seconds, attoseconds) = clock.now.offset.components
    return Date(timeIntervalSince1970: TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18)
  }
}

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
extension Transport {
  /// scripted is a transport on a simulation's clock and wall clock.
  static func scripted(
    _ simulation: Simulation,
    exchange: any HTTPExchange,
    credential: Credential = .publishable(key: "pk_test_abc"),
    language: String? = nil,
    retry: RetryPolicy = .standard,
    timeout: Duration = AttemptBudget.clientDefault,
    random: FixedRandom = FixedRandom(),
    onResponse: (@Sendable (ResponseReport) -> Void)? = nil
  ) -> Transport {
    Transport(
      configuration: Configuration(
        credential: credential,
        language: language,
        baseUrls: .standard,
        retry: retry,
        timeout: timeout,
        onResponse: onResponse
      ),
      exchange: exchange,
      sleeper: ClockSleeper(clock: simulation.clock),
      wallClock: SimulatedWallClock(clock: simulation.clock),
      random: random
    )
  }
}

extension RetryPolicy {
  /// quick is two retries after the first attempt and no wait of their own.
  static func quick(maxRetries: Int = 2, waitBudget: Duration = .seconds(60)) throws -> RetryPolicy
  {
    try RetryPolicy(
      maxRetries: maxRetries, baseDelay: .zero, maxDelay: .zero, waitBudget: waitBudget)
  }
}

extension OperationFacts {
  /// write is a REST write with the facts a test names.
  static func write(
    method: String = "POST",
    idempotent: Bool = false,
    key: Bool = true,
    conditional: Bool = false,
    credentials: CredentialDeclaration = CredentialDeclaration(),
    timeout: Duration? = .seconds(30)
  ) -> OperationFacts {
    OperationFacts(
      OperationDeclaration(
        operationId: "writeThing",
        method: method,
        idempotent: idempotent,
        credentials: credentials,
        timeout: timeout,
        declaresIdempotencyKey: key,
        isConditional: conditional
      ),
      path: "/v1/things"
    )
  }
}
